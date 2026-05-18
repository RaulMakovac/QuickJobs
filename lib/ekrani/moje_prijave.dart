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
      oglas: Oglas.fromJson(
        json['oglasi'],
      ), // 'oglasi' jer radimo join u selectu
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

  // 1. DOHVAĆANJE PRIJAVA
  // 1. DOHVAĆANJE PRIJAVA S ISPRAVNIM ALIASIMA
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
              naslov:naslov_oglasa,   
              opis:opis_oglasa,       
              isplata:isplata_oglasa, 
              adresa:adresa_oglasa,   
              status:status_oglasa,   
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

  // 2. LOGIKA ZA OCJENJIVANJE I BRISANJE PRIJAVE
  Future<void> _spremiRecenzijuAutora({
    required Prijava prijava, // Šaljemo cijelu prijavu
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

      // A) Prvo spremi recenziju
      await supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.autorId,
        'uloga_ocijenjenog': 'autor',
        'ocjena': ocjena,
        'komentar': komentar,
      });

      // B) Zatim obriši prijavu da se onemogući ponovno ocjenjivanje
      await supabase.from('prijave').delete().eq('id', prijava.id);

      if (mounted) {
        setState(() {}); // Osvježi listu (prijava nestaje)
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Greška: $e")));
      }
    }
  }

  // DIJALOG ZA OCJENU - Sada prima 'prijava' objekt
  void _pokaziDijalogZaOcjenuAutora(Prijava prijava) {
    int odabranaOcjena = 5;
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Ocijeni poslodavca", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Kako ste zadovoljni suradnjom na oglasu:\n'${prijava.oglas.naslov}'?",
                textAlign: TextAlign.center,
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
                    onPressed: () =>
                        setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: komentarController,
                decoration: InputDecoration(
                  hintText: "Napišite iskustvo...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2C29),
              ),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuAutora(
                  prijava: prijava,
                  ocjena: odabranaOcjena,
                  komentar: komentarController.text,
                );
              },
              child: const Text(
                "Spremi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _otkaziPrijavu(String prijavaId) async {
    try {
      await supabase.from('prijave').delete().eq('id', prijavaId);

      if (mounted) {
        // 1. Osvježavamo trenutni ekran (npr. listu tvojih prijava)
        setState(() {});

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prijava otkazana')));
      }
    } catch (e) {
      debugPrint("Greška pri otkazivanju: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBrown = Color(0xFF4A2C29);
    const bgColor = Color(0xFFE5D9D6);
    const cardColor = Color(0xFF8F6E68);

    return Scaffold(
      // 1. Postavljamo pozadinu na Scaffold
      backgroundColor: bgColor,
      // Dopušta krugovima da se vide i iza AppBara
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Moje prijave",
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBrown),
      ),
      // 2. Body omotamo u PozadinaKrugovi
      body: PozadinaKrugovi(
        child: SafeArea(
          child: FutureBuilder<List<Prijava>>(
            future: _dohvatiMojePrijave(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: darkBrown),
                );
              }

              final prijave = snapshot.data ?? [];
              if (prijave.isEmpty) {
                return const Center(
                  child: Text(
                    "Nema aktivnih prijava.",
                    style: TextStyle(
                      color: darkBrown,
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: zaposlenSam
                          ? (jeZavrseno
                                ? Colors.grey[400]
                                : const Color(0xFF6B8E23))
                          : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(
                          jeZavrseno
                              ? Icons.done_all
                              : (zaposlenSam
                                    ? Icons.celebration
                                    : Icons.hourglass_top),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        oglas.naslov,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        jeZavrseno
                            ? "Posao završen"
                            : (zaposlenSam
                                  ? "PRIHVAĆENI STE!"
                                  : "Na čekanju..."),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: (jeZavrseno && zaposlenSam)
                          ? ElevatedButton(
                              onPressed: () =>
                                  _pokaziDijalogZaOcjenuAutora(prijava),
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
                          : const Icon(Icons.info_outline, color: Colors.white),
                      onTap: () => _prikaziUpravljanjePrijavom(
                        context,
                        prijava,
                        zaposlenSam,
                        jeZavrseno,
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
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE5D9D6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                var oglasZaPrikaz = prijava.oglas;

                if (oglasZaPrikaz.autorIme == null ||
                    oglasZaPrikaz.autorIme == 'Nepoznat autor') {
                  final data = await supabase
                      .from('profiles')
                      .select('puno_ime')
                      .eq('id', oglasZaPrikaz.autorId ?? '')
                      .maybeSingle();

                  if (data != null) {
                    // ELEGANTNO: Samo "kopiramo" oglas s novim imenom
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2C29),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Dodirni za detalje oglasa",
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            if (zaposlenSam && !jeZavrseno)
              const Text(
                "Odabrani ste! Poslodavac će vas uskoro kontaktirati.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Zatvori"),
                  ),
                ),
                if (!zaposlenSam && !jeZavrseno) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _otkaziPrijavu(prijava.id);
                      },
                      child: const Text(
                        "Povuci prijavu",
                        style: TextStyle(color: Colors.red),
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
