import Flutter
import UIKit
import GoogleMobileAds  // 新增此行

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // 初始化 Google Mobile Ads SDK
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    GeneratedPluginRegistrant.register(with: self)
    
    // 註冊原生廣告工廠
    let nativeAdFactory = NativeAdFactory()
    FLTGoogleMobileAdsPlugin.sharedInstance().registerNativeAdFactory(
        self, 
        factoryId: "medium_template", 
        nativeAdFactory: nativeAdFactory
    )
    FLTGoogleMobileAdsPlugin.sharedInstance().registerNativeAdFactory(
        self, 
        factoryId: "small_template", 
        nativeAdFactory: nativeAdFactory
    )
    FLTGoogleMobileAdsPlugin.sharedInstance().registerNativeAdFactory(
        self, 
        factoryId: "full_screen_template", 
        nativeAdFactory: nativeAdFactory
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}