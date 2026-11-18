import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'oglas_service.dart'; // Za model Oglas

// --- MODEL ZA RECENZIJU ---
class Recenzija {
  final String id;
  final String ocjenjivacIme;
  final String oglasNaslov;
  final String? oglasKategorija;
  final int ocjena;
  final String? komentar;
  final String uloga;
  final DateTime createdAt;

  Recenzija({
    required this.id,
    required this.ocjenjivacIme,
    required this.oglasNaslov,
    required this.oglasKategorija,
    required this.ocjena,
    this.komentar,
    required this.uloga,
    required this.createdAt,
  });

  factory Recenzija.fromJson(Map<String, dynamic> json) {
    final ocjenjivacData = json['ocjenjivac'];
    final oglasData = json['oglasi'];
    return Recenzija(
      id: json['id'],
      ocjenjivacIme: ocjenjivacData != null
          ? ocjenjivacData['puno_ime']
          : 'Korisnik',
      oglasNaslov: oglasData != null ? oglasData['naslov_oglasa'] : 'Posao',
      ocjena: json['ocjena'],
      komentar: json['komentar'],
      uloga: json['uloga_ocijenjenog'],
      createdAt: DateTime.parse(json['created_at']),
      oglasKategorija: oglasData != null
          ? (oglasData['kategorija'] ?? 'Ostalo')
          : 'Ostalo',
    );
  }
}

// --- PODACI PROFILA ---
class PodaciProfila {
  final Map<String, dynamic> profil;
  final List<Oglas> oglasi;
  final List<Recenzija> recenzije;

  PodaciProfila({
    required this.profil,
    required this.oglasi,
    required this.recenzije,
  });
}

// --- SERVIS ZA PROFIL ---
class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<PodaciProfila> dohvatiPodatkeProfila(String ciljaniUserId) async {
    try {
      final profil = await _supabase
          .from('profiles')
          .select()
          .eq('id', ciljaniUserId)
          .single();

      final oglasiRes = await _supabase
          .from('oglasi')
          .select()
          .eq('autor_id', ciljaniUserId)
          .limit(10);

      final recenzijeRes = await _supabase
          .from('recenzije')
          .select('''
            *,
            ocjenjivac:profiles!recenzije_ocjenjivac_id_fkey(puno_ime),
            oglasi!recenzije_oglas_id_fkey(naslov_oglasa, kategorija)
          ''')
          .eq('ocijenjeni_id', ciljaniUserId)
          .order('created_at', ascending: false);

      final listOglasa = (oglasiRes as List)
          .map((json) => Oglas.fromJson(json))
          .toList();

      final listRecenzija = (recenzijeRes as List)
          .map((json) => Recenzija.fromJson(json))
          .toList();

      return PodaciProfila(
        profil: profil,
        oglasi: listOglasa,
        recenzije: listRecenzija,
      );
    } catch (e) {
      debugPrint("Greška u ProfileService.dohvatiPodatkeProfila: $e");
      rethrow;
    }
  }

  Future<void> azurirajProfil({
    required String userId,
    required String punoIme,
    required String telefon,
    required String opisProfila,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'puno_ime': punoIme.trim(),
            'telefon': telefon.trim(),
            'opis_profila': opisProfila.trim(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint("Greška u ProfileService.azurirajProfil: $e");
      rethrow;
    }
  }

  Future<bool> provjeriSmijeLiReportati(String prikazaniKorisnikId) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.id == prikazaniKorisnikId) return false;

    try {
      final response = await _supabase
          .from('oglasi')
          .select('id')
          .or('status_oglasa.eq.završen,status_oglasa.eq.obavljen')
          .or(
            'and(autor_id.eq.${user.id},obavljac_id.eq.$prikazaniKorisnikId),and(autor_id.eq.$prikazaniKorisnikId,obavljac_id.eq.${user.id})',
          );

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint("Greška pri provjeri suradnje: $e");
      return false;
    }
  }

  Future<void> prijaviKorisnika({
    required String prijavljeniKorisnikId,
    required String razlog,
    required String komentar,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Korisnik nije prijavljen.");

    try {
      await _supabase.from('reports').insert({
        'prijavitelj_id': user.id,
        'oglas_id': null,
        'prijavljeni_korisnik_id': prijavljeniKorisnikId,
        'razlog': razlog,
        'komentar': komentar.trim(),
      });
    } catch (e) {
      debugPrint("Greška u ProfileService.prijaviKorisnika: $e");
      rethrow;
    }
  }
}