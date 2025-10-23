package com.weatherpro.ai.android

import com.weatherpro.ai.android.R
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * MediumNativeAdFactory 是一個工廠類別，
 * 它的任務是將從 Google 取得的原生廣告資料，填入我們自訂的 my_native_ad.xml 版面中。
 */
class MediumNativeAdFactory(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {

    /**
     * 這個是唯一需要實作的方法。
     * 當 Google Mobile Ads 外掛程式成功載入一則原生廣告後，就會呼叫這個方法。
     * @param nativeAd 包含所有廣告素材 (標題、內文、圖片等) 的物件。
     * @return 一個填充好廣告資料的 NativeAdView。
     */
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        // 步驟 1: 將 my_native_ad.xml 這個「設計圖」實例化成一個真正的 View 物件。
        val adView = layoutInflater.inflate(R.layout.my_medium_native_ad, null) as NativeAdView

        // 步驟 2: 將 NativeAdView 內部定義好的各個 View (例如 headlineView, bodyView)
        //         和我們在 my_native_ad.xml 中定義的元件 (用 ID 尋找) 綁定在一起。
        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        // 步驟 3: 開始將 nativeAd 物件中的真實資料，填入對應的 View 中。
        // 標題是保證一定會有的素材。
        (adView.headlineView as? TextView)?.text = nativeAd.headline
        // 主要媒體內容 (圖片/影片) 也是保證會有的。
        adView.mediaView?.mediaContent = nativeAd.mediaContent

        // 步驟 4: 處理「可能不存在」的廣告素材。在設定前，務必先檢查是否為 null。
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.INVISIBLE // 如果沒有內文，就隱藏內文區塊
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as? TextView)?.text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE // 如果沒有行動呼籲按鈕文字
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as? Button)?.text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE // 如果沒有 App 圖標
        } else {
            (adView.iconView as? ImageView)?.setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd.advertiser == null) {
            adView.advertiserView?.visibility = View.INVISIBLE // 如果沒有廣告主名稱
        } else {
            (adView.advertiserView as? TextView)?.text = nativeAd.advertiser
            adView.advertiserView?.visibility = View.VISIBLE
        }
        
        // 步驟 5: 非常重要！將填充好的 adView 和 nativeAd 物件進行最終綁定。
        // 這樣 Google 才能追蹤點擊和曝光。
        adView.setNativeAd(nativeAd)

        return adView
    }
}