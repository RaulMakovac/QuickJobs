import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';
import '../dekor.dart';
import 'oglas.dart';

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

class MojePrijaveEkran extends StatefulWidget {
  const MojePrijaveEkran({super.key});

  @override
  State<MojePrijaveEkran> createState() => _MojePrijaveEkranState();
}

class _MojePrijaveEkranState extends State<MojePrijaveEkran> {
  final supabase = Supabase.instance.client;

  Future<List<Prijava>> _dohvatiMojePrijave() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
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
      debugPrint("Greška pri dohvaćanju: $e");
      return [];
    }
  }

  Future<void> _spremiRecenzijuAutora({
    required Prijava prijava,
    required int ocjena,
    String? komentar,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final oglas = prijava.oglas;

      if (oglas.autorId == null) {
        throw "Greška: ID autora nije pronađen.";
      }

      await supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.autorId,
        'uloga_ocijenjenog': 'autor',
        'ocjena': ocjena,
        'komentar': komentar,
      });

      await supabase.from('prijave').delete().eq('id', prijava.id);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Hvala na ocjeni! Posao je arhiviran."),
          ),
        );
      }
    } catch (e) {
      debugPrint("Greška pri recenziranju: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Greška: $e")));
      }
    }
  }

  void _pokaziDijalogZaOcjenuAutora(Prijava prijava, QuickJobsColors boje) {
    int odabranaOcjena = 5;
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: boje.bg,
          title: Text("Ocijeni poslodavca", textAlign: TextAlign.center, style: TextStyle(color: boje.A)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Kako ste zadovoljni suradnjom na oglasu:\n'${prijava.oglas.naslov}'?",
                textAlign: TextAlign.center,
                style: TextStyle(color: boje.A),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < odabranaOcjena ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 35,
                    ),
                    onPressed: () => setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: komentarController,
                style: TextStyle(color: boje.A),
                decoration: InputDecoration(
                  hintText: "Napišite iskustvo...",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: boje.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Odustani", style: TextStyle(color: boje.A)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: boje.A),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuAutora(
                  prijava: prijava,
                  ocjena: odabranaOcjena,
                  komentar: komentarController.text,
                );
              },
              child: Text("Spremi", style: TextStyle(color: boje.bg)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _otkaziPrijavu(Prijava prijava, bool zaposlenSam) async {
    try {
      final trenutniKorisnikId = supabase.auth.currentUser?.id;
      if (trenutniKorisnikId == null) return;

      if (zaposlenSam) {
        await supabase
            .from('oglasi')
            .update({
              'obavljac_id': null,
              'status_oglasa': 'otvoren', 
            })
            .eq('id', prijava.oglasId);
      }

      await supabase
          .from('chat_sobe')
          .update({
            'status': 'arhivirano',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('oglas_id', prijava.oglasId)
          .eq('radnik_id', trenutniKorisnikId);

      await supabase.from('prijave').delete().eq('id', prijava.id);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: zaposlenSam ? Colors.orange : Colors.green,
            content: Text(
              zaposlenSam
                  ? 'Uspješno ste se odjavili s posla. Chat je arhiviran.'
                  : 'Prijava uspješno povučena.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Greška pri otkazivanju: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Greška pri otkazivanju: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Moje prijave",
          style: TextStyle(color: boje.A, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: boje.A),
      ),
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: FutureBuilder<List<Prijava>>(
            future: _dohvatiMojePrijave(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: boje.A),
                );
              }

              final prijave = snapshot.data ?? [];
              if (prijave.isEmpty) {
                return Center(
                  child: Text(
                    "Nema aktivnih prijava.",
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: prijave.length,
                itemBuilder: (context, index) {
                  final prijava = prijave[index];
                  final oglas = prijava.oglas;
                  final user = supabase.auth.currentUser;

                  bool zaposlenSam = oglas.obavljacId == user?.id;
                  bool jeZavrseno = oglas.status == 'obavljen';

                  final ikonaPosla = kategorijeSaIkonama[oglas.kategorija] ?? Icons.hourglass_top;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: zaposlenSam
                          ? (jeZavrseno ? boje.B : Colors.green[700])
                          : boje.C,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: boje.bg?.withValues(alpha: 0.3),
                        child: Icon(
                          jeZavrseno
                              ? Icons.done_all
                              : (zaposlenSam ? Icons.celebration : ikonaPosla),
                          color: boje.A,
                        ),
                      ),
                      title: Text(
                        oglas.naslov,
                        style: TextStyle(
                          color: boje.A,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        jeZavrseno
                            ? "Posao završen"
                            : (zaposlenSam ? "PRIHVAĆENI STE!" : "Na čekanju..."),
                        style: TextStyle(color: boje.A?.withValues(alpha: 0.7)),
                      ),
                      trailing: (jeZavrseno && zaposlenSam)
                          ? ElevatedButton(
                              onPressed: () => _pokaziDijalogZaOcjenuAutora(prijava, boje),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "OCIJENI",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          : Icon(Icons.info_outline, color: boje.A),
                      onTap: () => _prikaziUpravljanjePrijavom(
                        context,
                        prijava,
                        zaposlenSam,
                        jeZavrseno,
                        boje,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _prikaziUpravljanjePrijavom(
    BuildContext context,
    Prijava prijava,
    bool zaposlenSam,
    bool jeZavrseno,
    QuickJobsColors boje,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: boje.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                var oglasZaPrikaz = prijava.oglas;

                if (oglasZaPrikaz.autorIme == null || oglasZaPrikaz.autorIme == 'Nepoznat autor') {
                  final data = await supabase
                      .from('profiles')
                      .select('puno_ime')
                      .eq('id', oglasZaPrikaz.autorId ?? '')
                      .maybeSingle();

                  if (data != null) {
                    oglasZaPrikaz = oglasZaPrikaz.copyWith(
                      autorIme: data['puno_ime'],
                    );
                  }
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetaljiOglasa(
                        oglas: oglasZaPrikaz,
                        samoPregled: true,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Text(
                    prijava.oglas.naslov,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Dodirni za detalje oglasa",
                    style: TextStyle(fontSize: 12, color: boje.A?.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if (zaposlenSam && !jeZavrseno)
              Text(
                "Odabrani ste! Poslodavac će vas uskoro kontaktirati.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: boje.A,
                ),
              ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: boje.C,
                      foregroundColor: boje.A,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Zatvori"),
                  ),
                ),
                if (!jeZavrseno) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _otkaziPrijavu(prijava, zaposlenSam);
                      },
                      child: Text(
                        zaposlenSam ? "Odjavi se s posla" : "Povuci prijavu",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}