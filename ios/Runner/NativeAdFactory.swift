// NativeAdFactory.swift

import google_mobile_ads

// 這個類別的用途是作為一個「工廠」，根據 Flutter 端傳來的 factoryId，
// 建立對應的原生廣告 UI，並將廣告資料填充進去。
class NativeAdFactory: NSObject, FLTNativeAdFactory {

    // 為了涵蓋所有範本 (小型、中型、全螢幕)，我們需要定義所有可能會用到的 IBOutlet 變數。
    // 即使某個範本沒有用到其中某個元件 (例如小型範本沒有 bodyView)，
    // 由於它們是可選類型 (Optional type, ?)，在後續操作中不會造成錯誤。
    @IBOutlet weak var headlineView: UILabel?
    @IBOutlet weak var bodyView: UILabel?
    @IBOutlet weak var callToActionView: UIButton?
    @IBOutlet weak var iconView: UIImageView?
    @IBOutlet weak var starRatingView: UILabel?
    @IBOutlet weak var storeView: UILabel?
    @IBOutlet weak var advertiserView: UILabel?
    @IBOutlet weak var mediaView: GADMediaView?

    /// 這個是 FLTNativeAdFactory 協定中唯一必須實作的方法。
    /// - Parameters:
    ///   - nativeAd: AdMob SDK 載入完成後回傳的廣告物件，包含所有廣告資料。
    ///   - customOptions: 從 Dart 端傳過來的額外參數，我們用它來傳遞 'factoryId'。
    /// - Returns: 一個填充好資料的 GADNativeAdView。
    func createNativeAd(_ nativeAd: GADNativeAd,
                        customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {

        // 步驟 1: 從 customOptions 中取得 factoryId，用來判斷要使用哪個 UI 範本。
        // 如果 Flutter 端沒有傳來 factoryId，就無法建立廣告，直接返回 nil。
        guard let factoryId = customOptions?["factoryId"] as? String else {
            print("錯誤：factoryId 未提供，無法建立原生廣告。")
            return nil
        }

        var nibName: String?
        // 步驟 2: 根據不同的 factoryId，決定要載入哪一個 .xib 檔案。
        // 這裡的字串 ("medium_template", "small_template" 等) 必須與您在 Dart 端呼叫時使用的 factoryId 一致。
        switch factoryId {
        case "medium_template":
            nibName = "GADTMediumTemplateView"
        case "small_template":
            nibName = "GADTSmallTemplateView"
        case "full_screen_template":
            nibName = "GADTFullScreenTemplateView"
        default:
            // 如果傳來的 factoryId 無法識別，則不載入任何範本。
            nibName = nil
        }

        // 如果找不到對應的 nibName，就無法繼續，返回 nil。
        guard let nibName = nibName else {
            print("錯誤：無效的 factoryId '\(factoryId)'。")
            return nil
        }

        // 步驟 3: 從 Bundle 中載入對應的 .xib 檔案，並將其轉換為 GADNativeAdView。
        // 這一步是將視覺化設計檔案實例化為程式碼可以操作的物件。
        guard let nativeAdView = Bundle.main.loadNibNamed(
            nibName,
            owner: nil,
            options: nil
        )?.first as? GADNativeAdView else {
            print("錯誤：無法從 \(nibName).xib 檔案載入 GADNativeAdView。請檢查檔案是否存在且設定正確。")
            return nil
        }
        
        // 步驟 4: 將廣告資料填充到 UI 元件中。
        // 因為 IBOutlet 都是可選類型，所以這裡的填充邏輯對所有範本是通用的。
        // 如果某個 view (例如 bodyView) 在某個範本中不存在，它就是 nil，? 會安全地處理這種情況，不會造成錯誤。
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.starRatingView as? UILabel)?.text = nativeAd.starRating?.description
        (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
        (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        // 步驟 5: 讓 AdMob SDK 能夠處理點擊和曝光事件，這是非常關鍵的一步。
        nativeAdView.nativeAd = nativeAd
        
        return nativeAdView
    }
}