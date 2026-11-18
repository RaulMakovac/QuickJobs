import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> prijaviOglas({
    required String oglasId,
    required String razlog,
    required String komentar,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Korisnik nije prijavljen.');
    }

    await _supabase.from('reports').insert({
      'prijavitelj_id': user.id,
      'oglas_id': oglasId,
      'razlog': razlog,
      'komentar': komentar,
    });
  }
}