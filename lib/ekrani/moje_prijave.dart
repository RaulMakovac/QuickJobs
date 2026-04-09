import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';

class MojePrijaveEkran extends StatefulWidget {
  const MojePrijaveEkran({super.key});

  @override
  State<MojePrijaveEkran> createState() => _MojePrijaveEkranState();
}

class _MojePrijaveEkranState extends State<MojePrijaveEkran> {
  final supabase = Supabase.instance.client;

  // 1. DOHVAĆANJE PRIJAVA
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška: $e")),
        );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    onPressed: () => setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: komentarController,
                decoration: InputDecoration(
                  hintText: "Napišite iskustvo...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2C29)),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuAutora(
                  prijava: prijava,
                  ocjena: odabranaOcjena,
                  komentar: komentarController.text,
                );
              },
              child: const Text("Spremi", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. FUNKCIJA ZA OTKAZIVANJE PRIJE POČETKA POSLA
  Future<void> _otkaziPrijavu(String prijavaId) async {
    try {
      await supabase.from('prijave').delete().eq('id', prijavaId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prijava otkazana')),
        );
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Moje prijave", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBrown),
      ),
      body: FutureBuilder<List<Prijava>>(
        future: _dohvatiMojePrijave(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: darkBrown));
          }

          final prijave = snapshot.data ?? [];
          if (prijave.isEmpty) {
            return const Center(
              child: Text("Nema aktivnih prijava.", style: TextStyle(color: darkBrown)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
                      ? (jeZavrseno ? Colors.grey[400] : const Color(0xFF6B8E23)) 
                      : cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(
                      jeZavrseno ? Icons.done_all : (zaposlenSam ? Icons.celebration : Icons.hourglass_top),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    oglas.naslov,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    jeZavrseno ? "Posao završen" : (zaposlenSam ? "PRIHVAĆENI STE!" : "Na čekanju..."),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: (jeZavrseno && zaposlenSam)
                      ? ElevatedButton(
                          onPressed: () => _pokaziDijalogZaOcjenuAutora(prijava), // Šalje prijavu
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("OCIJENI", style: TextStyle(color: Colors.white, fontSize: 10)),
                        )
                      : const Icon(Icons.info_outline, color: Colors.white),
                  onTap: () => _prikaziUpravljanjePrijavom(context, prijava, zaposlenSam, jeZavrseno),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _prikaziUpravljanjePrijavom(BuildContext context, Prijava prijava, bool zaposlenSam, bool jeZavrseno) {
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
            Text(prijava.oglas.naslov, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Status posla: ${prijava.oglas.status.toUpperCase()}"),
            const SizedBox(height: 20),
            if (zaposlenSam && !jeZavrseno)
              const Text("🎉 Odabrani ste! Poslodavac će vas uskoro kontaktirati.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Zatvori"),
                  ),
                ),
                if (!zaposlenSam && !jeZavrseno) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _otkaziPrijavu(prijava.id);
                      },
                      child: const Text("Povuci prijavu", style: TextStyle(color: Colors.red)),
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