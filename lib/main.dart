import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/weather/presentation/state/weather_data_state.dart';

import 'screens/splash_screen.dart';
import 'features/weather/presentation/screens/home_screen.dart';
import 'features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'features/radar/presentation/screen/radar_screen.dart';
import 'features/settings/screens/settings_screen.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'features/location/presentation/state/location_search_state.dart';

import 'features/location/data/services/location_storage_service.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'features/location/domain/usecases/get_saved_locations_usecase.dart';
import 'features/location/domain/usecases/save_location_usecase.dart';
import 'features/location/domain/usecases/remove_location_usecase.dart';
import 'features/location/domain/usecases/get_recent_searches_usecase.dart';
import 'features/location/domain/usecases/save_recent_search_usecase.dart';

import 'features/radar/data/services/radar_forecast_service.dart';
import 'features/radar/presentation/state/radar_state.dart';

import 'package:workmanager/workmanager.dart';
import 'dart:developer';
import 'background_tasks/evening_forecast_task_handler.dart';
import 'background_tasks/weather_alert_task_handler.dart';
import 'background_tasks/imminent_rain_task_handler.dart';
import 'background_tasks/fcm_background_handler.dart';

import 'dart:ui';

// Timezone packages
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// --- Platform Specific Imports ---
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode, kIsWeb; //【修改】導入 kReleaseMode
import 'dart:io' show Platform;

// --- 【新增】導入 App Check ---
import 'package:firebase_app_check/firebase_app_check.dart';

// --- Imports for Feature Flags & Services ---
import 'services/remote_config_service.dart';
import 'services/usage_limit_service.dart';
import 'services/announcement_service.dart';
// 【新增】導入安全服務
import 'services/error_reporting_service.dart';
import 'services/security_service.dart';
import 'widgets/maintenance_screen.dart';
import 'models/weather_forecast.dart';
import 'models/announcement.dart';

// --- Import UI and Navigation ---
import 'services/navigation_service.dart';
import 'widgets/announcement_dialog.dart';
import 'services/connectivity_service.dart';
import 'widgets/network_aware_widget.dart';
import 'widgets/interstitial_ad_manager.dart';

import 'features/ai_assistant/presentation/cubit/ai_assistant_cubit.dart';
import 'features/ai_assistant/data/services/firebase_ai_service.dart';
import 'features/ai_assistant/domain/services/gemini_tools.dart';

// --- MODIFICATION START: Import AppVersionService ---
import 'services/app_version_service.dart';
// --- MODIFICATION END ---


@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    log("Dispatching background task: $taskName", name: "Workmanager");

    switch (taskName) {
      case "weatherAlertTask":
        return await WeatherAlertTaskHandler().execute();
      case "eveningWeatherForecastTask":
        return await EveningForecastTaskHandler().execute();
      case "imminentRainTask":
        return await ImminentRainTaskHandler().execute();
      default:
        log("Unknown task: $taskName", name: "Workmanager");
        return Future.value(true);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    RootIsolateToken.instance;
  }
  
  tzdata.initializeTimeZones();
  await initializeDateFormatting('zh_TW', null);

  // 【保留】此判斷是正確且必要的，確保 Firebase 只初始化一次
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ★★★ 【啟用 Firestore 原生離線快取】 ★★★
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // 使用無限制快取或設定一個具體值
  );
  
  // 【新增】初始化安全服務，並在檢測到關鍵威脅時終止 App
  // 僅在 Release 模式的行動裝置上啟用，以避免影響開發和測試
  // if (!kIsWeb && kReleaseMode) {
  if (!kIsWeb) {
    final errorReportingService = ErrorReportingService();
    final securityService = SecurityService(reportingService: errorReportingService);
    // 初始化並開始監聽。如果檢測到 critical 威脅，這一步就會終止 App
    await securityService.initialize();
  }
  
  if (!kIsWeb) {
    // 【新增】初始化 Firebase App Check
    await FirebaseAppCheck.instance.activate(
      webProvider: null,
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  }
  
  // 【保留】使用您原始的正確函數名稱
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final remoteConfigService = await RemoteConfigService.getInstance();
  await remoteConfigService.fetchAndActivate();
  
  // --- MODIFICATION START: Initialize AppVersionService ---
  final appVersionService = AppVersionService();
  await appVersionService.initialize();
  // --- MODIFICATION END ---

  final prefs = await SharedPreferences.getInstance();
  final announcementService = AnnouncementService(prefs);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Workmanager().cancelAll(); // ADDED: Forcefully cancel any stale tasks from previous builds
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    MobileAds.instance.initialize();
  }
  
  final appDependencies = AppDependencies();

  final locationStorageService = LocationStorageService();
  final locationRepository = LocationRepositoryImpl(locationStorageService);
  final getSavedLocationsUseCase = GetSavedLocationsUseCase(
    locationRepository,
  );
  final saveLocationUseCase = SaveLocationUseCase(locationRepository);
  final removeLocationUseCase = RemoveLocationUseCase(locationRepository);
  final getRecentSearchesUseCase = GetRecentSearchesUseCase(
    locationRepository,
  );
  final saveRecentSearchUseCase = SaveRecentSearchUseCase(locationRepository);

  runApp(
    MultiProvider(
      providers: [
        // 【無修改】您的 Provider 列表保持原樣，因為原本就沒有 SecurityProvider
        Provider<RemoteConfigService>.value(value: remoteConfigService),
        // --- MODIFICATION START: Provide AppVersionService ---
        Provider<AppVersionService>.value(value: appVersionService),
        // --- MODIFICATION END ---
        ChangeNotifierProvider<AnnouncementService>.value(value: announcementService),
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
        Provider<ConnectivityService>(
          create: (_) => ConnectivityService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<UsageLimitService>(
          create: (context) => UsageLimitService(
            authService: context.read<AuthService>(),
            remoteConfigService: context.read<RemoteConfigService>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => FirestoreService()),
        ChangeNotifierProvider(
          create:
              (_) => LocationSearchState(
                getSavedLocationsUseCase: getSavedLocationsUseCase,
                saveLocationUseCase: saveLocationUseCase,
                removeLocationUseCase: removeLocationUseCase,
                getRecentSearchesUseCase: getRecentSearchesUseCase,
                saveRecentSearchUseCase: saveRecentSearchUseCase,
              ),
        ),
        ChangeNotifierProvider(
          create: (context) => WeatherDataState(
            dependencies: appDependencies,
            connectivityService: context.read<ConnectivityService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => RadarForecastService(
            remoteConfigService: context.read<RemoteConfigService>(),
          )..initializeAndStartFetching(),
        ),
        ChangeNotifierProvider(
          create: (context) => RadarState(
            forecastService: context.read<RadarForecastService>(),
          ),
        ),
        BlocProvider<AiAssistantCubit>(
          create: (context) {
            final dependencies = AppDependencies();
            final geminiTools = GeminiTools(
              weatherDataState: Provider.of<WeatherDataState>(context, listen: false),
              observationRepository: dependencies.observationRepository,
              uvIndexRepository: dependencies.uvIndexRepository,
              airQualityRepository: dependencies.airQualityRepository,
              weatherForecastRepository: dependencies.weatherForecastRepository,
              locationService: dependencies.locationService,
              radarForecastService: Provider.of<RadarForecastService>(context, listen: false),
            );

            final firebaseAiService = FirebaseAiService(
              remoteConfigService: Provider.of<RemoteConfigService>(context, listen: false),
              geminiTools: geminiTools,
            );

            return AiAssistantCubit(
              weatherDataState: Provider.of<WeatherDataState>(context, listen: false),
              observationRepository: dependencies.observationRepository,
              uvIndexRepository: dependencies.uvIndexRepository,
              airQualityRepository: dependencies.airQualityRepository,
              weatherForecastRepository: dependencies.weatherForecastRepository,
              locationService: dependencies.locationService,
              radarForecastService: Provider.of<RadarForecastService>(context, listen: false),
              remoteConfigService: Provider.of<RemoteConfigService>(context, listen: false),
              usageLimitService: Provider.of<UsageLimitService>(context, listen: false),
              aiAssistantService: firebaseAiService,
            )..initialize();
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台灣天氣通',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Noto Sans TC',
      ),
      builder: (context, child) {
        return NetworkAwareWidget(child: child!);
      },
      initialRoute: '/splash',
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFCMListeners();
    _checkUnreadAnnouncementsOnStartup();
    
    if (!kIsWeb) {
      final remoteConfigService = context.read<RemoteConfigService>();
      // Pass it to the loadAd method
      InterstitialAdManager.instance.loadAd(remoteConfigService: remoteConfigService);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final announcementService = context.read<AnnouncementService>();
      announcementService.refresh().then((_) {
        _checkUnreadAnnouncementsOnStartup();
      });
    }
  }

  void _setupFCMListeners() {
    // Listener for messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final announcementService = context.read<AnnouncementService>();
      
      // Call the new "smart" method
      final newAnnouncement = await announcementService.addAnnouncementFromFCM(message);

      // If a new announcement was successfully added (not a duplicate),
      // show the dialog for it.
      if (newAnnouncement != null && mounted) {
        _showAnnouncementDialog(newAnnouncement);
      }
    });
  }

  void _checkUnreadAnnouncementsOnStartup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final announcementService = context.read<AnnouncementService>();
      if (announcementService.unreadCount > 0) {
        final latestUnread = announcementService.announcements.firstWhere((a) => !a.isRead, orElse: () => announcementService.announcements.first);
        _showAnnouncementDialog(latestUnread);
        announcementService.markAllAsRead();
      }
    });
  }

  Future<void> _showAnnouncementDialog(Announcement announcement) async {
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return AnnouncementDialog(announcement: announcement);
        },
      );
    }
  }

  void _onItemTapped(int index) {
    if (!kIsWeb && index != _selectedIndex) {
      final remoteConfigService = context.read<RemoteConfigService>();
      InterstitialAdManager.instance.showAd(remoteConfigService: remoteConfigService);
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = Provider.of<RemoteConfigService>(context, listen: false);

    final List<Widget> widgetOptions = <Widget>[
      remoteConfig.isHomeEnabled ? const HomeScreen() : const MaintenanceScreen(),
      remoteConfig.isAiAssistantEnabled ? const AiAssistantScreenProvider() : const MaintenanceScreen(),
      remoteConfig.isRadarEnabled ? const RadarScreen() : const MaintenanceScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Center(child: widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: '首頁天氣',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.auto_awesome),
            icon: Icon(Icons.auto_awesome_outlined),
            label: 'AI助手',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.satellite_alt),
            icon: Icon(Icons.satellite_alt_outlined),
            label: '降雨雷達',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
