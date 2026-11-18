import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- MODEL Oglas ---
class Oglas {
  final String id;
  final String naslov;
  final String opis;
  final String isplata;
  final String adresa;
  final String status;
  final String? autorIme;
  final String? autorId;
  final String? obavljacId;
  final String? obavljacIme;
  final DateTime createdAt;
  final bool jeReportan;
  final String kategorija;

  Oglas({
    required this.id,
    required this.naslov,
    required this.opis,
    required this.isplata,
    required this.adresa,
    required this.status,
    this.autorIme,
    this.autorId,
    this.obavljacId,
    this.obavljacIme,
    required this.createdAt,
    this.jeReportan = false,
    this.kategorija = "Ostalo",
  });

  Oglas copyWith({String? autorIme}) {
    return Oglas(
      id: id,
      naslov: naslov,
      opis: opis,
      isplata: isplata,
      adresa: adresa,
      status: status,
      autorId: autorId,
      obavljacId: obavljacId,
      obavljacIme: obavljacIme,
      createdAt: createdAt,
      autorIme: autorIme ?? this.autorIme,
      jeReportan: jeReportan,
      kategorija: kategorija,
    );
  }

  factory Oglas.fromJson(Map<String, dynamic> json) {
    final profileData = json['autor'] as Map<String, dynamic>?;
    final obavljacData = json['obavljac'] as Map<String, dynamic>?;
    final reportsList = json['reports'] as List?;
    final bool reportan = reportsList != null && reportsList.isNotEmpty;

    return Oglas(
      id: json['id'] ?? '',
      naslov: json['naslov_oglasa'] ?? 'Bez naslova',
      opis: json['opis_oglasa'] ?? '',
      isplata: json['isplata_oglasa']?.toString() ?? '0',
      adresa: json['adresa_oglasa'] ?? '',
      status: json['status_oglasa'] ?? 'otvoren',
      obavljacId: json['obavljac_id'],
      obavljacIme: obavljacData?['puno_ime'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      autorId: profileData?['id'] ?? json['autor_id']?.toString(),
      autorIme: profileData?['puno_ime'] ?? 'Autor oglasa',
      jeReportan: reportan,
      kategorija: json['kategorija'] ?? 'Ostalo',
    );
  }
}

// --- SERVIS ZA OGLASE ---
class OglasService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Dohvat oglasa za glavni ekran
  Future<List<Oglas>> dohvatiDostupneOglase({
    String searchQuery = "",
    double minIsplata = 0,
    String? odabranaKategorija,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final prijaveResponse = await _supabase
          .from('prijave')
          .select('oglas_id')
          .eq('korisnik_id', user.id);

      final prijavljeniOglasiIds = (prijaveResponse as List)
          .map((item) => item['oglas_id'].toString())
          .toList();

      var query = _supabase
          .from('oglasi')
          .select(
            '*, autor:profiles!oglasi_autor_id_fkey(puno_ime), reports(id)',
          )
          .eq('status_oglasa', 'otvoren')
          .filter('obavljac_id', 'is', null);

      if (prijavljeniOglasiIds.isNotEmpty) {
        query = query.not('id', 'in', '(${prijavljeniOglasiIds.join(',')})');
      }

      query = query.neq('autor_id', user.id);

      if (searchQuery.isNotEmpty) {
        query = query.ilike('naslov_oglasa', '%$searchQuery%');
      }

      if (minIsplata > 0) {
        query = query.gte('isplata_oglasa', minIsplata);
      }

      if (odabranaKategorija != null &&
          odabranaKategorija != "Sve kategorije") {
        query = query.eq('kategorija', odabranaKategorija);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Greška u OglasService.dohvatiDostupneOglase: $e");
      return [];
    }
  }

  // 2. Ažuriranje oglasa
  Future<void> azurirajOglas({
    required String oglasId,
    required String naslov,
    required String opis,
    required String isplata,
    required String adresa,
  }) async {
    try {
      await _supabase
          .from('oglasi')
          .update({
            'naslov_oglasa': naslov.trim(),
            'opis_oglasa': opis.trim(),
            'isplata_oglasa': isplata.trim(),
            'adresa_oglasa': adresa.trim(),
          })
          .eq('id', oglasId);
    } catch (e) {
      debugPrint("Greška u OglasService.azurirajOglas: $e");
      rethrow;
    }
  }

  // 3. Dohvat mojih oglasa (za ekran MojiOglasi)
  Future<List<Oglas>> dohvatiMojeOglase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('oglasi')
          .select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime), obavljac:profiles!oglasi_obavljac_id_fkey(puno_ime)')
          .eq('autor_id', user.id)
          .order('created_at', ascending: false);

      final List data = response as List;
      List<Oglas> sviOglasi = data.map((json) => Oglas.fromJson(json)).toList();

      sviOglasi.sort((a, b) {
        if (a.status == 'obavljen' && b.status != 'obavljen') return 1;
        if (a.status != 'obavljen' && b.status == 'obavljen') return -1;
        return 0;
      });

      return sviOglasi;
    } catch (e) {
      debugPrint("Greška u OglasService.dohvatiMojeOglase: $e");
      return [];
    }
  }

  // 4. Reaktivacija oglasa
  Future<void> reaktivirajOglas(String oglasId, String? stariObavljacId) async {
    try {
      if (stariObavljacId != null) {
        await _supabase
            .from('chat_sobe')
            .update({'status': 'arhivirano'})
            .eq('oglas_id', oglasId);
      }

      await _supabase.from('oglasi').update({
        'status_oglasa': 'otvoren',
        'obavljac_id': null,
      }).eq('id', oglasId);
    } catch (e) {
      debugPrint("Greška u OglasService.reaktivirajOglas: $e");
      rethrow;
    }
  }

  // 5. Spremanje recenzije i završavanje posla
  Future<void> spremiRecenzijuIZavrsi({
    required Oglas oglas,
    required int ocjena,
    String? komentar,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || oglas.obavljacId == null) {
        throw Exception("Korisnik nije prijavljen ili radnik nije odabran.");
      }

      await _supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.obavljacId,
        'uloga_ocijenjenog': 'obavljač',
        'ocjena': ocjena,
        'komentar': komentar,
      });

      await _supabase.from('oglasi').update({'status_oglasa': 'obavljen'}).eq('id', oglas.id);
      await _supabase.from('chat_sobe').update({'status': 'arhivirano'}).eq('oglas_id', oglas.id);
    } catch (e) {
      debugPrint("Greška u OglasService.spremiRecenzijuIZavrsi: $e");
      rethrow;
    }
  }

  // 6. Trajno brisanje oglasa
  Future<void> trajnoObrisiOglas(String id) async {
    try {
      await _supabase.from('oglasi').delete().eq('id', id);
    } catch (e) {
      debugPrint("Greška u OglasService.trajnoObrisiOglas: $e");
      rethrow;
    }
  }
  
  Future<void> objaviOglas({
    required String naslov,
    required String adresa,
    required String isplata,
    required String opis,
    required String kategorija,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception("Korisnik nije prijavljen.");
      }

      await _supabase.from('oglasi').insert({
        'autor_id': user.id,
        'naslov_oglasa': naslov.trim(),
        'adresa_oglasa': adresa.trim(),
        'isplata_oglasa': isplata.trim(),
        'opis_oglasa': opis.trim(),
        'kategorija': kategorija,
        'status_oglasa': 'otvoren',
      });
    } catch (e) {
      debugPrint("Greška u OglasService.objaviOglas: $e");
      rethrow;
    }
  }
}

