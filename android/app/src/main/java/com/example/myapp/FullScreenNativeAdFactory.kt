// 檔案: android/app/src/main/java/com/example/myapp/FullScreenNativeAdFactory.kt
package com.example.myapp

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class FullScreenNativeAdFactory(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        // 載入我們新的全螢幕佈局
        val adView = layoutInflater.inflate(R.layout.my_fullscreen_native_ad, null) as NativeAdView

        // 綁定所有必要的 View
        adView.mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        // --- 填充資料 ---
        // 主要媒體和標題是保證存在的
        adView.mediaView?.mediaContent = nativeAd.mediaContent
        (adView.headlineView as? TextView)?.text = nativeAd.headline

        // 檢查可能為 null 的欄位
        if (nativeAd.body == null) {
            adView.bodyView?.visibility = View.GONE
        } else {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as? TextView)?.text = nativeAd.body
        }

        if (nativeAd.callToAction == null) {
            adView.callToActionView?.visibility = View.INVISIBLE
        } else {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as? Button)?.text = nativeAd.callToAction
        }

        if (nativeAd.icon == null) {
            adView.iconView?.visibility = View.GONE
        } else {
            (adView.iconView as? ImageView)?.setImageDrawable(nativeAd.icon?.drawable)
            adView.iconView?.visibility = View.VISIBLE
        }

        if (nativeAd.advertiser == null) {
            adView.advertiserView?.visibility = View.GONE
        } else {
            (adView.advertiserView as? TextView)?.text = nativeAd.advertiser
            adView.advertiserView?.visibility = View.VISIBLE
        }

        // 最終綁定，讓廣告可被追蹤和點擊
        adView.setNativeAd(nativeAd)

        return adView
    }
}