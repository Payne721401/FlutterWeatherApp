import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// 一個全局的狀態管理器，負責追蹤和提供使用者的訂閱狀態。
///
/// UI Widget 應該監聽這個 Provider 來決定是否顯示廣告或提供付費功能。
/// 它的設計與後端（Firebase Custom Claims）解耦，方便獨立開發和測試。
class SubscriptionState with ChangeNotifier {
  final AuthService _authService;

  int _subscriptionLevel = 0; // 私有變數，儲存使用者的會員等級
  bool _isLoading = true;     // 私有變數，追蹤是否正在從後端獲取狀態

  // --- Public Getters ---
  // UI 應該使用這些 getter 來讀取狀態，而不是直接存取私有變數。

  /// 使用者的訂閱等級 (例如：0=免費, 1=高級會員)。
  int get subscriptionLevel => _subscriptionLevel;

  /// 一個簡單方便的判斷，代表使用者是否為付費會員。
  /// 這是 UI 判斷是否顯示廣告最主要的依據。
  bool get isPremium => _subscriptionLevel > 0;

  /// 狀態是否仍在從後端載入中。
  bool get isLoading => _isLoading;

  /// 建構函式：
  /// 當 SubscriptionState 的實例被建立時，會立即檢查一次訂閱狀態。
  SubscriptionState(this._authService) {
    // 注意：這裡不使用 await，因為建構函式不能是異步的。
    // checkSubscriptionStatus 方法內部會自行處理狀態更新。
    checkSubscriptionStatus();
  }

  /// 核心方法：檢查並更新使用者的訂閱狀態。
  ///
  /// 這個方法是 Flutter App 與 Firebase 後端的橋樑。
  /// 它會呼叫 AuthService 來獲取最新的 Custom Claim。
  /// 當您的 Cloud Function 準備好後，這裡不需要任何改動。
  Future<void> checkSubscriptionStatus({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners(); // 步驟 1: 通知所有監聽者，我們正要開始載入

    // 呼叫 AuthService 的方法來獲取 Custom Claim。
    // 即使後端還沒好，這個方法也會安全地回傳 0。
    _subscriptionLevel = await _authService.getSubscriptionLevel(forceRefresh: forceRefresh);
    
    _isLoading = false;
    notifyListeners(); // 步驟 2: 獲取到結果後，再次通知監聽者更新 UI
  }

  /// 當使用者登出時，呼叫此方法以重設狀態為預設值。
  void clear() {
    _subscriptionLevel = 0;
    _isLoading = false;
    notifyListeners();
  }
}
