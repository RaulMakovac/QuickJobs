import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> registrirajKorisnika({
    required String email,
    required String password,
    required String punoIme,
    required String telefon,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'puno_ime': punoIme.trim(),
          'telefon': telefon.trim(),
        },
      );
    } catch (e) {
      debugPrint("Greška u AuthService.registrirajKorisnika: $e");
      rethrow;
    }
  }
  Future<void> prijavaKorisnika({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      debugPrint("Greška u AuthService.prijavaKorisnika: $e");
      rethrow;
    }
  }
}
