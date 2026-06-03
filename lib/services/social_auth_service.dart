import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SocialAuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Google Sign-In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in cancelled'};
      }

      // Get Google authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send the ID token to your Laravel backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/google'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'id_token': googleAuth.idToken,
              'access_token': googleAuth.accessToken,
            }),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save token
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }
        return {'success': true, 'data': data, 'user': googleUser};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed on server',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in error: $e'};
    }
  }

  /// Sign in with Facebook
  static Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      // Trigger Facebook sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        return {'success': false, 'message': 'Facebook sign-in cancelled'};
      }

      if (result.status != LoginStatus.success) {
        return {'success': false, 'message': 'Facebook sign-in failed'};
      }

      // Get access token
      final AccessToken? accessToken = result.accessToken;

      if (accessToken == null) {
        return {'success': false, 'message': 'No access token received'};
      }

      // Get user profile
      final Map<String, dynamic> userData = await FacebookAuth.instance
          .getUserData(fields: "email,name,picture");

      // Send the access token to your Laravel backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/facebook'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'access_token': accessToken.token}),
          )
          .timeout(ApiConfig.timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save token
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
        }
        return {'success': true, 'data': data, 'user': userData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Facebook login failed on server',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Facebook sign-in error: $e'};
    }
  }

  /// Sign out from all social providers
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();

    // Clear local token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
