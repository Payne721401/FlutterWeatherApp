import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // 確保已導入 kIsWeb

// 根據平台條件式導入正確的實作檔案
// 使用 'as platform_impl' 給予一個別名，以便在下面引用
import 'package:myapp/features/radar/presentation/widgets/numerical_forecast_view_mobile.dart'
    if (dart.library.html) 'package:myapp/features/radar/presentation/widgets/numerical_forecast_view_web.dart' as platform_impl;

// 定義一個抽象的基底類別，用於所有平台實作的共同介面
abstract class BaseNumericalForecastView extends StatefulWidget {
  final bool shouldLoad;
  const BaseNumericalForecastView({super.key, required this.shouldLoad});
}

class NumericalForecastView extends StatelessWidget {
  final bool shouldLoad;

  const NumericalForecastView({super.key, required this.shouldLoad});

  @override
  Widget build(BuildContext context) {
    // 現在使用別名來引用 NumericalForecastViewImpl
    // 這個類別會在 numerical_forecast_view_mobile.dart 或 numerical_forecast_view_web.dart 中定義
    return platform_impl.NumericalForecastViewImpl(shouldLoad: shouldLoad);
  }
}
