// File: ios/Runner/NativeAdFactoryExample.m

#import "NativeAdFactoryExample.h"

@implementation NativeAdFactoryExample

// 這個方法是核心，它負責建立廣告視圖並填入資料
- (GADNativeAdView *)createNativeAd:(GADNativeAd *)nativeAd
                      customOptions:(NSDictionary *)customOptions {
  // 載入我們稍後會建立的 UI 介面檔案 "NativeAdView.xib"
  GADNativeAdView *adView =
      [[NSBundle mainBundle] loadNibNamed:@"NativeAdView" owner:nil options:nil].firstObject;

  // --- 開始將廣告資料填入 UI 元件 ---

  // 標題 (一定會有)
  ((UILabel *)adView.headlineView).text = nativeAd.headline;

  // 內文 (不一定有，所以要檢查)
  ((UILabel *)adView.bodyView).text = nativeAd.body;
  adView.bodyView.hidden = nativeAd.body ? NO : YES;

  // 行動呼籲按鈕 (不一定有)
  [((UIButton *)adView.callToActionView) setTitle:nativeAd.callToAction
                                         forState:UIControlStateNormal];
  adView.callToActionView.hidden = nativeAd.callToAction ? NO : YES;

  // 圖示 (不一定有)
  ((UIImageView *)adView.iconView).image = nativeAd.icon.image;
  adView.iconView.hidden = nativeAd.icon ? NO : YES;

  // 其他欄位...
  ((UILabel *)adView.storeView).text = nativeAd.store;
  adView.storeView.hidden = nativeAd.store ? NO : YES;

  ((UILabel *)adView.priceView).text = nativeAd.price;
  adView.priceView.hidden = nativeAd.price ? NO : YES;

  ((UILabel *)adView.advertiserView).text = nativeAd.advertiser;
  adView.advertiserView.hidden = nativeAd.advertiser ? NO : YES;

  // 禁用按鈕的用戶互動，讓 SDK 處理點擊
  adView.callToActionView.userInteractionEnabled = NO;

  // 關鍵步驟：將 adView 和 nativeAd 物件關聯起來，廣告才能點擊
  adView.nativeAd = nativeAd;

  return adView;
}

@end