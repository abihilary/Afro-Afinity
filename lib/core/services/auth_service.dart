import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/user_profile.dart';

part 'auth_service.g.dart';

@riverpod
class AuthService extends _$AuthService {
  final _supabase = Supabase.instance.client;

  @override
  FutureOr<void> build() async {
    // Initialization logic if needed
  }

  Future<bool> signInWithEmail(String email, String password) async {
    debugPrint('Attempting email sign in for: $email');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('Email sign in response: ${response.user != null}');
      return response.user != null;
    } catch (e) {
      debugPrint('Email sign in error: $e');
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    debugPrint('Attempting email sign up for: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      debugPrint('Email sign up response: ${response.user != null}');
      return response.user != null;
    } catch (e) {
      debugPrint('Email sign up error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    debugPrint('Attempting native Google sign in...');
    try {
      // 1. Trigger Native Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign in cancelled by user');
        return false;
      }

      debugPrint('Google user signed in: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('Google sign in failed: idToken is null');
        return false;
      }

      debugPrint('Google idToken obtained, signing in to Supabase...');
      // 2. Use the ID Token to sign in to Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      debugPrint('Supabase Google sign in response: ${response.user != null}');
      return response.user != null;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String code) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: '', // In a real flow, you'd pass the email here
        token: code,
        type: OtpType.signup,
      );

      return response.session != null;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<String?> getCurrentToken() async {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  bool isTokenExpired(String token) {
    return false;
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            ...profile.toMap(),
          });

      return true;
    } catch (e) {
      debugPrint('Update user profile error: $e');
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return false;

      // Consider onboarding complete if they have a display name and interests
      return (data['display_name'] != null &&
              (data['interests'] as List?)?.isNotEmpty == true);
    } catch (e) {
      debugPrint('Check onboarding status error: $e');
      return false;
    }
  }
}

