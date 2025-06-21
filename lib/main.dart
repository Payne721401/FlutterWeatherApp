import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/weather/presentation/state/weather_state.dart';
import 'screens/splash_screen.dart';
import 'features/weather/presentation/screens/home_screen.dart';
import 'features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'features/radar/presentation/screen/radar_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// WebView Imports for Platform Initialization (removed manual setup, rely on automatic)
import 'package:webview_flutter/webview_flutter.dart'; // Still needed for WebViewWidget and WebViewController types
// No longer explicitly importing platform-specific webview_flutter packages here
// as they are automatically linked by pubspec.yaml and Flutter's build system.

// Removed 'dart:io' as Platform checks are no longer needed in main.
// import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb might be used elsewhere, keeping it.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_TW', null);
  MobileAds.instance.initialize();

  // --- Firebase Initialization ---
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  // --- End Firebase Initialization ---

  // --- WebView Flutter Platform Initialization ---
  // In recent versions of webview_flutter, explicit platform setup in main() 
  // is often not necessary if the platform-specific packages are correctly
  // included in pubspec.yaml. Flutter's build system will automatically
  // pick the correct implementation for the target platform (Android, iOS, Web).
  // Removed manual setting of WebViewPlatform.instance.
  // --- End WebView Flutter Platform Initialization ---

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WeatherState()),
        ChangeNotifierProvider(create: (context) => FirestoreService()),
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
