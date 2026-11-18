import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'oglas_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get trenutniKorisnikId => _supabase.auth.currentUser?.id;

  // --- ZA CHAT HUB ---

  Stream<List<Map<String, dynamic>>> dohvatiMojeSobe() {
    return _supabase
        .from('chat_sobe')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false);
  }

  Future<Map<String, dynamic>> dohvatiPodatkeZaKarticu(
    Map<String, dynamic> soba,
  ) async {
    try {
      final mojId = _supabase.auth.currentUser!.id;

      final sugovornikId = soba['klijent_id'] == mojId
          ? soba['radnik_id']
          : soba['klijent_id'];

      if (sugovornikId == null || sugovornikId == '') {
        return {
          'puno_ime': 'Soba bez korisnika',

          'naslov_oglasa': 'Info',

          'zadnja_poruka': '',

          'sugovornik_id': '',
        };
      }

      final profilRes = await _supabase
          .from('profiles')
          .select('puno_ime')
          .eq('id', sugovornikId)
          .maybeSingle();

      final oglasRes = await _supabase
          .from('oglasi')
          .select('naslov_oglasa')
          .eq('id', soba['oglas_id'])
          .maybeSingle();

      final porukaRes = await _supabase
          .from('poruke')
          .select('tekst')
          .eq('soba_id', soba['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return {
        'puno_ime': profilRes?['puno_ime'] ?? 'Nepoznat korisnik',

        'naslov_oglasa': oglasRes?['naslov_oglasa'] ?? 'Oglas uklonjen',

        'zadnja_poruka': porukaRes?['tekst'] ?? 'Započnite razgovor...',

        'sugovornik_id': sugovornikId,
      };
    } catch (e) {
      debugPrint("Greška u ChatService.dohvatiPodatkeZaKarticu: $e");

      return {
        'puno_ime': 'Greška',

        'naslov_oglasa': '!',

        'zadnja_poruka': 'Provjerite vezu',

        'sugovornik_id': '',
      };
    }
  }

  // --- ZA INDIVIDUALNI CHAT (chat.dart) ---

  Stream<List<Map<String, dynamic>>> pratiSobu(String sobaId) {
    return _supabase
        .from('chat_sobe')
        .stream(primaryKey: ['id'])
        .eq('id', sobaId);
  }

  Stream<List<Map<String, dynamic>>> pratiPoruke(String sobaId) {
    return _supabase
        .from('poruke')
        .stream(primaryKey: ['id'])
        .eq('soba_id', sobaId)
        .order('created_at', ascending: false);
  }

  Future<String> dohvatiImeSugovornika(String sugovornikId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('puno_ime')
          .eq('id', sugovornikId)
          .maybeSingle();

      return data?['puno_ime'] ?? 'Nepoznati korisnik';
    } catch (e) {
      debugPrint("Greška u ChatService.dohvatiImeSugovornika: $e");

      return 'Nepoznati korisnik';
    }
  }

  Future<Oglas?> dohvatiOglasZaChat(String oglasId) async {
    try {
      final res = await _supabase
          .from('oglasi')
          .select()
          .eq('id', oglasId)
          .maybeSingle();

      if (res != null) {
        return Oglas.fromJson(res);
      }

      return null;
    } catch (e) {
      debugPrint("Greška u ChatService.dohvatiOglasZaChat: $e");

      rethrow;
    }
  }

  Future<void> posaljiPoruku({
    required String sobaId,

    required String tekst,
  }) async {
    final mojId = trenutniKorisnikId;

    if (mojId == null) throw Exception("Korisnik nije prijavljen.");

    try {
      await _supabase.from('poruke').insert({
        'soba_id': sobaId,

        'posiljatelj_id': mojId,

        'tekst': tekst.trim(),
      });

      await _supabase
          .from('chat_sobe')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', sobaId);
    } catch (e) {
      debugPrint("Greška u ChatService.posaljiPoruku: $e");

      rethrow;
    }
  }

  Future<void> obrisiChatSobu(String sobaId) async {
    try {
      await _supabase.from('chat_sobe').delete().eq('id', sobaId);
    } catch (e) {
      debugPrint("Greška u ChatService.obrisiChatSobu: $e");

      rethrow;
    }
  }
}
