// android/app/src/main/java/com/example/myapp/MainActivity.kt

package com.weatherpro.ai.android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 註冊小型廣告工廠，ID 為 'adFactorySmall'
        val factorySmall = SmallNativeAdFactory(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "adFactorySmall", factorySmall)

        // 註冊中型廣告工廠，ID 改為 'adFactoryMedium'，與 Flutter 端完全對應
        val factoryMedium = MediumNativeAdFactory(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "adFactoryMedium", factoryMedium)

        // 註冊全螢幕廣告，ID為"adFactoryFullScreen"
        val factoryFullScreen = FullScreenNativeAdFactory(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "adFactoryFullScreen", factoryFullScreen)
    }

    // 這是一個好習慣，可以在 Flutter 引擎銷毀時，取消註冊，避免記憶體洩漏
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        // 取消註冊時，也必須使用註冊時的同一個 ID
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactorySmall")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactoryMedium")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "adFactoryFullScreen")
    }
}