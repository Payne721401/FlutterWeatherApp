import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // MODIFICATION: Import Cupertino widgets
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:weatherpro/features/weather/presentation/state/weather_data_state.dart';
import '../services/auth_service.dart';
import '../widgets/animated_logo.dart';

// This function ONLY handles navigation now.
Future<void> _navigateToHome(BuildContext context) async {
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/home');
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      body: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingUI();
          }

          // --- MODIFICATION START: Reverted to simple logic ---
          if (snapshot.hasData) {
            // Any logged-in user (permanent or anonymous) goes to home.
            return const _NavigateToHome();
          }
          // --- MODIFICATION END ---

          return const _LoginUI();
        },
      ),
    );
  }
}

// --- UI Components ---

class _LoadingUI extends StatelessWidget {
  const _LoadingUI();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFf8fafc), Color(0xFFe2e8f0)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedLogo(size: 150),
            const SizedBox(height: 24),
            Text(
              '台灣AI天氣通',
              style: GoogleFonts.notoSansTc(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0f172a),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF475569)),
            ),
            const SizedBox(height: 20),
            Text(
              '正在檢查登入狀態...',
              style: GoogleFonts.notoSansTc(
                fontSize: 14,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginUI extends StatelessWidget {
  const _LoginUI();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf8fafc), Color(0xFFe2e8f0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                const AnimatedLogo(size: 140),
                const SizedBox(height: 24),
                Text(
                  '台灣AI天氣通',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '你的天氣小幫手',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Spacer(flex: 2),
                _LoginButton(
                  text: '使用 Google 帳號登入',
                  iconPath: 'assets/icons/google_logo.svg',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF1f2937),
                  borderColor: const Color(0xFFd1d5db),
                  onPressed: () async {
                    await authService.signInWithGoogle();
                  },
                ),
                const SizedBox(height: 16),
                
                if (authService.isAppleSignInAvailable) ...[
                  _LoginButton(
                    text: '使用 Apple ID 登入',
                    iconPath: 'assets/icons/apple_logo.svg',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    onPressed: () async {
                      await authService.signInWithApple();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                _LoginButton(
                  text: '稍後再登入',
                  isOutlined: true,
                  textColor: const Color(0xFF334155),
                  borderColor: const Color(0xFF94a3b8),
                  onPressed: () async {
                    await authService.signInAnonymously();
                  },
                ),
                const Spacer(flex: 4),
                Text(
                  '繼續使用即表示您同意我們的服務條款和隱私政策',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 11,
                    color: const Color(0xFF64748b),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String text;
  final String? iconPath;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.text,
    this.iconPath,
    this.backgroundColor = Colors.transparent,
    required this.textColor,
    this.borderColor,
    this.isOutlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = (isOutlined
            ? OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor ?? Colors.transparent, width: 1.5),
              )
            : ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: textColor,
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.15),
              ))
        .copyWith(
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    final textWidget = Text(
      text,
      style: GoogleFonts.notoSansTc(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconPath != null) SvgPicture.asset(iconPath!, height: 22, colorFilter: textColor == Colors.white ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null),
        if (iconPath != null) const SizedBox(width: 16),
        textWidget,
      ],
    );

    return isOutlined
        ? OutlinedButton(
            style: buttonStyle,
            onPressed: onPressed,
            child: buttonContent,
          )
        : ElevatedButton(
            style: buttonStyle,
            onPressed: onPressed,
            child: buttonContent,
          );
  }
}

class _NavigateToHome extends StatefulWidget {
  const _NavigateToHome();

  @override
  State<_NavigateToHome> createState() => _NavigateToHomeState();
}

class _NavigateToHomeState extends State<_NavigateToHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePermissionsAndLoadData();
    });
  }
  
  Future<void> _handlePermissionsAndLoadData() async {
    if (kIsWeb) {
      // For web, just load data and navigate.
      await context.read<WeatherDataState>().fetchDataForCurrentLocation();
      if (mounted) _navigateToHome(context);
      return;
    }

    // --- Mobile Permission Logic ---
    var permissionStatus = await Permission.locationWhenInUse.status;

    if (permissionStatus.isDenied) {
      final bool userAgreed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog( // MODIFICATION: Changed to Cupertino Style
          title: const Text('需要定位權限'),
          content: const Text('允許定位後，我們可以即時提供您所在位置的天氣預報。'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('允許'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ) ?? false;

      if (userAgreed) {
        await Permission.locationWhenInUse.request();
      }
    }

    // --- Data Loading ---
    // This now happens AFTER the permission flow.
    if (mounted) {
      await context.read<WeatherDataState>().fetchDataForCurrentLocation();
    }

    // --- Navigation ---
    if (mounted) {
      _navigateToHome(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
