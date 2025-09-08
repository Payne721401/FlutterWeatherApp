import 'dart:convert';
import 'dart:developer' as dev; // 使用 alias 避免衝突
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// AuthService 封裝了所有 Firebase Authentication 相關的邏輯，
/// 包括 Google 登入、Apple 登入和登出功能。
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// 提供一個 Stream 來監聽認證狀態的變化。
  /// UI 層可以監聽此 Stream 來響應使用者的登入或登出。
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 取得目前已登入的使用者物件。
  User? get currentUser => _auth.currentUser;

  /// 檢查 Apple 登入是否在當前平台可用。
  /// Apple 登入僅在 iOS 和 macOS 實體設備上受支援。
  bool get isAppleSignInAvailable =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// 執行 Google 登入流程。
  ///
  Future<User?> signInWithGoogle() async {
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        dev.log(
          'This platform does not support Google authentication',
          name: 'AuthService',
        );
        return null;
      }

      final String serverClientId =
          '98663574060-uo1v5sa8ktqb0vgvr004tebo58gnlq8s.apps.googleusercontent.com';

      await _googleSignIn.initialize(serverClientId: serverClientId);

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.authenticate();

      if (googleUser == null) {
        // 使用者取消了登入流程
        dev.log('User canceled Google sign-in', name: 'AuthService');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // --- MODIFICATION START: Reverted to simple sign-in ---
      dev.log('Signing in with Google...', name: 'AuthService');
      final userCredential = await _auth.signInWithCredential(credential);
      // --- MODIFICATION END ---

      dev.log(
        'Google sign-in successful for user: ${userCredential.user?.email}',
        name: 'AuthService',
      );
      return userCredential.user;
    } on GoogleSignInException catch (e) {
      dev.log(
        'Google Sign-In Exception: ${e.code} - ${e.description}',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
      return null;
    } on FirebaseAuthException catch (e) {
      dev.log(
        'Firebase Auth Exception (Google): ${e.message}',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
      return null;
    } catch (e) {
      dev.log(
        'An unexpected error occurred (Google): $e',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
      return null;
    }
  }

  /// 執行 Apple 登入流程。
  ///
  Future<User?> signInWithApple() async {
    if (!isAppleSignInAvailable) {
      throw UnsupportedError(
        'Apple Sign-In is not available on this platform.',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      dev.log('Starting Apple sign-in process', name: 'AuthService');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // --- MODIFICATION START: Reverted to simple sign-in ---
      dev.log('Signing in with Apple...', name: 'AuthService');
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      // --- MODIFICATION END ---
      
      dev.log('Apple sign-in successful', name: 'AuthService');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      dev.log(
        'Firebase Auth Exception (Apple): ${e.message}',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
      return null;
    } catch (e) {
      dev.log(
        'An unexpected error occurred (Apple): $e',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
      return null;
    }
  }

  /// 執行匿名登入流程。
  ///
  /// 成功時返回 `User` 物件，若發生錯誤則返回 `null`。
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      dev.log('Signed in anonymously: ${userCredential.user?.uid}', name: 'AuthService');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      dev.log(
        'Firebase Auth Exception (Anonymous): ${e.message}',
        name: 'AuthService',
        level: 1000,
      );
      return null;
    } catch (e) {
      dev.log(
        'An unexpected error occurred (Anonymous): $e',
        name: 'AuthService',
        level: 1000,
      );
      return null;
    }
  }

  /// 執行登出流程。
  /// 會同時登出 Firebase、Google 和 Apple 帳號。
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      dev.log('User signed out successfully', name: 'AuthService');
    } catch (e) {
      dev.log(
        'Error during sign out: $e',
        name: 'AuthService',
        level: 1000,
      ); // ERROR level
    }
  }

  /// 產生一個隨機的字串作為 Nonce。
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
