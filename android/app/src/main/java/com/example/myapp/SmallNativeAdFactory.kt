// 檔案: android/app/src/main/java/com/example/myapp/SmallNativeAdFactory.kt
package com.example.myapp

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class SmallNativeAdFactory(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        // 這裡載入我们新的小型佈局
        val adView = layoutInflater.inflate(R.layout.my_small_native_ad, null) as NativeAdView

        // 綁定 View
        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.advertiserView = adView.findViewById(R.id.ad_advertiser)

        // 填充資料
        (adView.headlineView as? TextView)?.text = nativeAd.headline
        (adView.callToActionView as? Button)?.text = nativeAd.callToAction

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

        adView.setNativeAd(nativeAd)
        return adView
    }
}