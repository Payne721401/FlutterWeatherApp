import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weatherpro/services/auth_service.dart';
import 'package:weatherpro/services/remote_config_service.dart';
import 'package:weatherpro/services/usage_limit_service.dart';

// --- MOCKS ---
class MockAuthService extends Mock implements AuthService {}
class MockRemoteConfigService extends Mock implements RemoteConfigService {}
class MockUser extends Mock implements User {
  @override
  final String uid;

  MockUser({this.uid = 'test_uid'});
}

// --- Manual Mocks for Firebase Transaction ---
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}
class MockTransactionResult extends Mock implements TransactionResult {}

void main() {
  // --- TEST SETUP ---
  late MockAuthService mockAuthService;
  late MockRemoteConfigService mockRemoteConfigService;
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockDbRef;
  late UsageLimitService usageLimitService;

  late MockUser mockUser;
  late StreamController<User?> authStateController;

  const String fakeUid = 'test_uid';

  Map<String, dynamic> getUtcPlus8DayInfo(DateTime dateTime) {
    final nowInUtcPlus8 = dateTime.toUtc().add(const Duration(hours: 8));
    final startOfDayInUtcPlus8 = DateTime.utc(nowInUtcPlus8.year, nowInUtcPlus8.month, nowInUtcPlus8.day);
    final startOfDayInUtc = startOfDayInUtcPlus8.subtract(const Duration(hours: 8));
    return {
      'dateString': DateFormat('yyyy-MM-dd').format(startOfDayInUtcPlus8),
      'dayTimestamp': startOfDayInUtc.millisecondsSinceEpoch,
    };
  }

  setUp(() {
    mockAuthService = MockAuthService();
    mockRemoteConfigService = MockRemoteConfigService();
    mockDatabase = MockFirebaseDatabase();
    mockDbRef = MockDatabaseReference();
    mockUser = MockUser(uid: fakeUid);
    authStateController = StreamController<User?>.broadcast();

    when(() => mockRemoteConfigService.aiDailyMessageLimitLevel1).thenReturn(20);
    when(() => mockRemoteConfigService.aiDailyImageLimitLevel1).thenReturn(10);
    when(() => mockRemoteConfigService.aiCheckFactor).thenReturn(1);

    when(() => mockAuthService.currentUser).thenReturn(null);
    when(() => mockAuthService.authStateChanges).thenAnswer((_) => authStateController.stream);

    when(() => mockDatabase.ref(any())).thenReturn(mockDbRef);
    when(() => mockDbRef.child(any())).thenReturn(mockDbRef);

    usageLimitService = UsageLimitService.internal(
      authService: mockAuthService,
      remoteConfigService: mockRemoteConfigService,
      database: mockDatabase,
    );
  });

  tearDown(() {
    authStateController.close();
    usageLimitService.dispose();
  });

  void simulateLogin(User? user) {
    when(() => mockAuthService.currentUser).thenReturn(user);
    authStateController.add(user);
  }

  Future<void> waitForInitialization(UsageLimitService service) {
    if (service.isInitialized) return Future.value();
    final completer = Completer<void>();
    void listener() {
      if (service.isInitialized) {
        completer.complete();
        service.removeListener(listener);
      }
    }
    service.addListener(listener);
    return completer.future;
  }

  void mockTransactionFlow(Map<String, dynamic>? initialData) {
    when(() => mockDbRef.runTransaction(any())).thenAnswer((invocation) async {
      final handler = invocation.positionalArguments.first as TransactionHandler;
      final mutableDataCopy = initialData == null ? null : Map<String, dynamic>.from(initialData);
      final resultOfHandler = handler(mutableDataCopy);
      final dynamic successResult = resultOfHandler;
      final finalSnapshot = MockDataSnapshot();
      when(() => finalSnapshot.value).thenReturn(successResult.value);
      when(() => finalSnapshot.exists).thenReturn(true);
      final transactionResult = MockTransactionResult();
      when(() => transactionResult.committed).thenReturn(true);
      when(() => transactionResult.snapshot).thenReturn(finalSnapshot);
      return transactionResult;
    });
  }
  
  void mockInitialSync(Map<String, dynamic>? initialData) {
      final initialSnapshot = MockDataSnapshot();
      when(() => initialSnapshot.exists).thenReturn(initialData != null);
      when(() => initialSnapshot.value).thenReturn(initialData);
      when(() => mockDbRef.get()).thenAnswer((_) async => initialSnapshot);
  }

  group('Initialization and Authentication', () {
    test('當用戶登入時，應同步資料庫計數', () async {
      // Arrange
      final todayInfo = getUtcPlus8DayInfo(DateTime.now());
      mockInitialSync({
        'count': 5,
        'image_count': 2,
        'dayTimestamp': todayInfo['dayTimestamp'],
      });

      // Act
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);

      // Assert
      expect(usageLimitService.isInitialized, isTrue);
      expect(usageLimitService.dailyMessageCount, 5);
      expect(usageLimitService.dailyImageCount, 2);
    });

    test('當用戶在新的一天登入時，本地計數應重置為 0', () async {
      // Arrange
      final yesterdayInfo = getUtcPlus8DayInfo(DateTime.now().subtract(const Duration(days: 1)));
      mockInitialSync({
        'count': 15,
        'image_count': 8,
        'dayTimestamp': yesterdayInfo['dayTimestamp'],
      });

      // Act
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);

      // Assert
      expect(usageLimitService.isInitialized, isTrue);
      expect(usageLimitService.dailyMessageCount, 0);
      expect(usageLimitService.dailyImageCount, 0);
    });

    test('當用戶登出時，應重置所有本地狀態', () async {
      // Arrange
      mockInitialSync(null);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      expect(usageLimitService.isInitialized, isTrue);

      // Act
      simulateLogin(null);
      await Future.delayed(Duration.zero);

      // Assert
      expect(usageLimitService.dailyMessageCount, 0);
      expect(usageLimitService.dailyImageCount, 0);
      expect(usageLimitService.isInitialized, isFalse);
    });
  });

  group('runProtectedAiAction (Message Usage)', () {
    test('用量未滿時，應成功執行並增加計數', () async {
      // Arrange
      final initialData = {
        'count': 5,
        'image_count': 2,
        'dayTimestamp': getUtcPlus8DayInfo(DateTime.now())['dayTimestamp'],
      };
      mockInitialSync(initialData);
      mockTransactionFlow(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      bool actionExecuted = false;

      // Act
      await usageLimitService.runProtectedAiAction(() async { actionExecuted = true; });

      // Assert
      expect(actionExecuted, isTrue);
      expect(usageLimitService.dailyMessageCount, 6);
    });

    test('當 Action 本身失敗時，不應增加計數', () async {
      // Arrange
      final initialData = {
        'count': 5,
        'image_count': 2,
        'dayTimestamp': getUtcPlus8DayInfo(DateTime.now())['dayTimestamp'],
      };
      mockInitialSync(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      final testException = Exception('AI Service Failed');

      // Act & Assert
      await expectLater(
        () => usageLimitService.runProtectedAiAction(() async { throw testException; }),
        throwsA(equals(testException)),
      );
      expect(usageLimitService.dailyMessageCount, 5); // Verify count is unchanged
    });

    test('用量已滿時，應拋出 UsageLimitException', () async {
      // Arrange
      final initialData = {
        'count': 20, // At limit
        'image_count': 2,
        'dayTimestamp': getUtcPlus8DayInfo(DateTime.now())['dayTimestamp'],
      };
      mockInitialSync(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      bool actionExecuted = false;

      // Act & Assert
      expect(
        () => usageLimitService.runProtectedAiAction(() async { actionExecuted = true; }),
        throwsA(isA<UsageLimitException>()),
      );
      expect(actionExecuted, isFalse);
    });

    test('跨日重置時，應原子性地重置兩個計數器', () async {
      // Arrange
      final yesterdayInfo = getUtcPlus8DayInfo(DateTime.now().subtract(const Duration(days: 1)));
      final initialData = {
        'count': 15,
        'image_count': 8,
        'dayTimestamp': yesterdayInfo['dayTimestamp'],
      };
      mockInitialSync(initialData);
      mockTransactionFlow(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);

      // Act
      await usageLimitService.runProtectedAiAction(() async {});

      // Assert
      expect(usageLimitService.dailyMessageCount, 1);
      expect(usageLimitService.dailyImageCount, 0);
    });
  });

  group('runProtectedImageAction (Image Usage)', () {
    test('用量未滿且操作成功時，應增加計數', () async {
      // Arrange
      final initialData = {
        'count': 5,
        'image_count': 2,
        'dayTimestamp': getUtcPlus8DayInfo(DateTime.now())['dayTimestamp'],
      };
      mockInitialSync(initialData);
      mockTransactionFlow(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      bool actionExecuted = false;

      // Act
      await usageLimitService.runProtectedImageAction(() async { actionExecuted = true; });

      // Assert
      expect(actionExecuted, isTrue);
      expect(usageLimitService.dailyImageCount, 3);
      expect(usageLimitService.dailyMessageCount, 5);
    });

    test('當 Action 本身失敗時，不應增加計數', () async {
      // Arrange
      final initialData = {
        'count': 5,
        'image_count': 2,
        'dayTimestamp': getUtcPlus8DayInfo(DateTime.now())['dayTimestamp'],
      };
      mockInitialSync(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);
      final testException = Exception('Generator Failed');

      // Act & Assert
      await expectLater(
        () => usageLimitService.runProtectedImageAction(() async { throw testException; }),
        throwsA(equals(testException)),
      );

      // Assert
      expect(usageLimitService.dailyImageCount, 2);
    });

    test('跨日重置時，應原子性地重置兩個計數器', () async {
      // Arrange
      final yesterdayInfo = getUtcPlus8DayInfo(DateTime.now().subtract(const Duration(days: 1)));
      final initialData = {
        'count': 15,
        'image_count': 8,
        'dayTimestamp': yesterdayInfo['dayTimestamp'],
      };
      mockInitialSync(initialData);
      mockTransactionFlow(initialData);
      simulateLogin(mockUser);
      await waitForInitialization(usageLimitService);

      // Act
      await usageLimitService.runProtectedImageAction(() async {});

      // Assert
      expect(usageLimitService.dailyImageCount, 1);
      expect(usageLimitService.dailyMessageCount, 0);
    });
  });
}
