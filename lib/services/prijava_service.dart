import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'oglas_service.dart'; // Za model Oglas

// --- MODEL PRIJAVA ---
class Prijava {
  final String id;
  final String oglasId;
  final Oglas oglas;
  final DateTime createdAt;

  Prijava({
    required this.id,
    required this.oglasId,
    required this.oglas,
    required this.createdAt,
  });

  factory Prijava.fromJson(Map<String, dynamic> json) {
    return Prijava(
      id: json['id'],
      oglasId: json['oglas_id'],
      oglas: Oglas.fromJson(json['oglasi']), 
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// --- SERVIS ZA PRIJAVE ---
class PrijavaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Metoda za prijavu korisnika na oglas (koju koristi DetaljiOglasa)
  Future<void> prijavaNaOglas(String oglasId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Korisnik nije prijavljen.');
      }

      await _supabase.from('prijave').insert({
        'oglas_id': oglasId,
        'korisnik_id': user.id,
      });
    } catch (e) {
      debugPrint("Greška u PrijavaService.prijavaNaOglas: $e");
      rethrow;
    }
  }

  // Dohvat prijava trenutnog korisnika (za MojePrijaveEkran)
  Future<List<Prijava>> dohvatiMojePrijave() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('prijave')
          .select('''
            *,
            oglasi:oglas_id (
              id,
              naslov_oglasa,   
              opis_oglasa,       
              isplata_oglasa, 
              adresa_oglasa,   
              status_oglasa,   
              kategorija,       
              autor_id,
              obavljac_id,
              created_at
            )
          ''')
          .eq('korisnik_id', user.id)
          .order('created_at', ascending: false);

      final List data = response as List;
      return data.map((json) => Prijava.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Greška u PrijavaService.dohvatiMojePrijave: $e");
      return [];
    }
  }

  // Spremanje recenzije poslodavca i brisanje prijave
  Future<void> spremiRecenzijuAutora({
    required Prijava prijava,
    required int ocjena,
    String? komentar,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Korisnik nije prijavljen.");

      final oglas = prijava.oglas;
      if (oglas.autorId == null) {
        throw "Greška: ID autora nije pronađen.";
      }

      await _supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.autorId,
        'uloga_ocijenjenog': 'autor',
        'ocjena': ocjena,
        'komentar': komentar?.trim(),
      });

      await _supabase.from('prijave').delete().eq('id', prijava.id);
    } catch (e) {
      debugPrint("Greška u PrijavaService.spremiRecenzijuAutora: $e");
      rethrow;
    }
  }

  // Otkazivanje prijave ili odjava s posla
  Future<void> otkaziPrijavu({
    required Prijava prijava,
    required bool zaposlenSam,
  }) async {
    try {
      final trenutniKorisnikId = _supabase.auth.currentUser?.id;
      if (trenutniKorisnikId == null) return;

      if (zaposlenSam) {
        await _supabase
            .from('oglasi')
            .update({
              'obavljac_id': null,
              'status_oglasa': 'otvoren', 
            })
            .eq('id', prijava.oglasId);
      }

      await _supabase
          .from('chat_sobe')
          .update({
            'status': 'arhivirano',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('oglas_id', prijava.oglasId)
          .eq('radnik_id', trenutniKorisnikId);

      await _supabase.from('prijave').delete().eq('id', prijava.id);
    } catch (e) {
      debugPrint("Greška u PrijavaService.otkaziPrijavu: $e");
      rethrow;
    }
  }
}