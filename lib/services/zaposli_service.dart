import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ZaposliService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Dohvat prijavljenih korisnika za oglas, sortirano po ocjeni

  Future<List<Map<String, dynamic>>> dohvatiPrijavljeneKorisnike(
    String oglasId,
  ) async {
    try {
      final response = await _supabase
          .from('prijave')
          .select('*, profiles(id, puno_ime, telefon, ocjena_korisnika)')
          .eq('oglas_id', oglasId);

      List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(
        response,
      );

      lista.sort((a, b) {
        double ocjenaA = (a['profiles']['ocjena_korisnika'] ?? 0.0).toDouble();

        double ocjenaB = (b['profiles']['ocjena_korisnika'] ?? 0.0).toDouble();

        return ocjenaB.compareTo(ocjenaA);
      });

      return lista;
    } catch (e) {
      debugPrint("Greška u ZaposliService.dohvatiPrijavljeneKorisnike: $e");

      return [];
    }
  }

  // 2. Prihvaćanje kandidata (postavlja obavljača, briše ostale prijave i otvara chat)

  Future<void> prihvatiKandidata({
    required String oglasId,

    required String kandidatId,
  }) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) throw Exception("Korisnik nije prijavljen.");

    try {
      // Ažuriraj oglas: postavi obavljača i promijeni status

      await _supabase
          .from('oglasi')
          .update({'obavljac_id': kandidatId, 'status_oglasa': 'u_tijeku'})
          .eq('id', oglasId);

      // Obriši prijave svih ostalih kandidata za ovaj oglas

      await _supabase
          .from('prijave')
          .delete()
          .eq('oglas_id', oglasId)
          .neq('korisnik_id', kandidatId);

      // Kreiraj ili osvježi chat sobu između klijenta i radnika

      await _supabase.from('chat_sobe').upsert({
        'oglas_id': oglasId,

        'klijent_id': currentUser.id,

        'radnik_id': kandidatId,

        'status': 'aktivno',
      }, onConflict: 'oglas_id');
    } catch (e) {
      debugPrint("Greška u ZaposliService.prihvatiKandidata: $e");

      rethrow;
    }
  }

  // 3. Odbijanje pojedinog kandidata

  Future<List<dynamic>> odbijKandidata({
    required String oglasId,

    required String kandidatId,
  }) async {
    try {
      final List<dynamic> obrisaniRedci = await _supabase
          .from('prijave')
          .delete()
          .eq('oglas_id', oglasId)
          .eq('korisnik_id', kandidatId)
          .select();

      return obrisaniRedci;
    } catch (e) {
      debugPrint("Greška u ZaposliService.odbijKandidata: $e");

      rethrow;
    }
  }
}
