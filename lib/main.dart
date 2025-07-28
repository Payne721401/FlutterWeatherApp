import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'services/firestore_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'features/location/presentation/state/location_search_state.dart';

import 'features/location/data/services/location_storage_service.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'features/location/domain/usecases/get_saved_locations_usecase.dart';
import 'features/location/domain/usecases/save_location_usecase.dart';
import 'features/location/domain/usecases/remove_location_usecase.dart';

import 'features/radar/data/services/radar_forecast_service.dart';

import 'package:workmanager/workmanager.dart';
import 'dart:developer';
import 'background_tasks/evening_forecast_task_handler.dart';
import 'background_tasks/weather_alert_task_handler.dart';
import 'background_tasks/imminent_rain_task_handler.dart';

// Timezone packages
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;


// --- Platform Specific Imports ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    log("Dispatching task: $taskName", name: "Workmanager");

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

  // Initialize timezone data
  tzdata.initializeTimeZones();

  // Initialize Workmanager only on mobile platforms
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  await initializeDateFormatting('zh_TW', null);
  MobileAds.instance.initialize();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await RadarForecastService().initializeAndStartFetching();

  final appDependencies = AppDependencies();

  final locationStorageService = LocationStorageService();
  final locationRepository = LocationRepositoryImpl(locationStorageService);
  final getSavedLocationsUseCase = GetSavedLocationsUseCase(locationRepository);
  final saveLocationUseCase = SaveLocationUseCase(locationRepository);
  final removeLocationUseCase = RemoveLocationUseCase(locationRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FirestoreService()),
        ChangeNotifierProvider(
          create: (_) => LocationSearchState(
            getSavedLocationsUseCase: getSavedLocationsUseCase,
            saveLocationUseCase: saveLocationUseCase,
            removeLocationUseCase: removeLocationUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WeatherDataState(dependencies: appDependencies),
        ),
        ChangeNotifierProvider(create: (context) => RadarForecastService()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Noto Sans TC',
      ),
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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    AiAssistantScreen(),
    RadarScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
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
