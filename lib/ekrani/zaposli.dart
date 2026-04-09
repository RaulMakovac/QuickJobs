import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart'; 
import '/ekrani/korisnicki_profil.dart'; 

class Zaposli extends StatefulWidget {
  final Oglas oglas;
  const Zaposli({super.key, required this.oglas});

  @override
  State<Zaposli> createState() => _ZaposliState();
}

class _ZaposliState extends State<Zaposli> {
  final supabase = Supabase.instance.client;

  // --- LOGIKA: DOHVAĆANJE KANDIDATA ---
  Future<List<Map<String, dynamic>>> _dohvatiPrijavljeneKorisnike() async {
    final response = await supabase
        .from('prijave')
        .select('*, profiles(id, puno_ime, telefon, ocjena_korisnika)')
        .eq('oglas_id', widget.oglas.id);

    List<Map<String, dynamic>> lista = List<Map<String, dynamic>>.from(response);

    lista.sort((a, b) {
      double ocjenaA = (a['profiles']['ocjena_korisnika'] ?? 0.0).toDouble();
      double ocjenaB = (b['profiles']['ocjena_korisnika'] ?? 0.0).toDouble();
      return ocjenaB.compareTo(ocjenaA);
    });

    return lista;
  }

 // --- LOGIKA: PRIHVATI KANDIDATA ---
  Future<void> _prihvatiKandidata(String kandidatId) async {
    try {
      // 1. Postavi radnika i promijeni status oglasa
      await supabase.from('oglasi').update({
        'obavljac_id': kandidatId,
        'status_oglasa': 'u_tijeku', 
      }).eq('id', widget.oglas.id);

      // 2. Obriši prijave svih OSTALIH korisnika, ali OSTAVI prihvaćenog
      await supabase
          .from('prijave')
          .delete()
          .eq('oglas_id', widget.oglas.id)
          .neq('korisnik_id', kandidatId); // <--- KLJUČNA PROMJENA: "briši sve gdje ID NIJE kandidatId"

      if (mounted) {
        Navigator.pop(context); // Zatvori modal
        Navigator.pop(context); // Vrati se na prethodni ekran
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green, 
            content: Text("Radnik zaposlen! Njegova prijava je sačuvana.")
          ),
        );
      }
    } catch (e) {
      debugPrint("Greška pri prihvaćanju: $e");
    }
  }

  // --- LOGIKA: ODBIJ KANDIDATA ---
  Future<void> _odbijKandidata(String kandidatId) async {
    try {
      // Brišemo samo tu jednu prijavu (korisnik_id se obično zove stupac u 'prijave')
      await supabase.from('prijave').delete()
          .eq('oglas_id', widget.oglas.id)
          .eq('korisnik_id', kandidatId);

      if (mounted) {
        Navigator.pop(context); // Zatvori modal
        setState(() {}); // Osvježi listu kandidata
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kandidat odbijen.")),
        );
      }
    } catch (e) {
      debugPrint("Greška pri odbijanju: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBrown = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      appBar: AppBar(
        title: Text(widget.oglas.naslov),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkBrown,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dohvatiPrijavljeneKorisnike(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: darkBrown));
          }
          if (snapshot.hasError) return Center(child: Text("Greška: ${snapshot.error}"));

          final prijave = snapshot.data ?? [];
          final brojPrijava = prijave.length;

          return Column(
            children: [
              // HEADER BOX
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8F6E68),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ukupno prijava: $brojPrijava", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 5),
                        const Text("Pregledajte kandidate ispod", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.group, color: Colors.white, size: 40),
                  ],
                ),
              ),

              const Text("LISTA KANDIDATA", style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
              const Divider(indent: 50, endIndent: 50),

              Expanded(
                child: prijave.isEmpty
                    ? const Center(child: Text("Još nema prijava."))
                    : ListView.builder(
                        itemCount: prijave.length,
                        itemBuilder: (context, index) {
                          final profil = prijave[index]['profiles'];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: const CircleAvatar(backgroundColor: Color(0xFFD1BDB9), child: Icon(Icons.person, color: darkBrown)),
                              title: Text(profil['puno_ime'] ?? "Korisnik", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Ocjena: ${profil['ocjena_korisnika'] ?? '0.0'} ★"),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8F6E68)),
                              onTap: () => _prikaziDetaljeKandidata(profil),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _prikaziDetaljeKandidata(Map<String, dynamic> profil) {
    final ocjena = profil['ocjena_korisnika'];
    final imaOcjenu = ocjena != null && ocjena > 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE5D9D6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 60, color: Color(0xFF4A2C29)),
            const SizedBox(height: 10),
            Text(profil['puno_ime'] ?? "Korisnik", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A2C29))),
            Text(imaOcjenu ? "Ocjena: $ocjena/5 ★" : "Nema recenzija", style: const TextStyle(color: Colors.black54)),
            
            const SizedBox(height: 25),

            // TIPKA: UVID U PROFIL
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => KorisnickiProfil(prikazaniKorisnikId: profil['id'])));
              },
              icon: const Icon(Icons.person_search, color: Colors.white),
              label: const Text("UVID U PROFIL PRIJAVLJENOG", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F6E68),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 15),

            // TIPKE: PRIHVATI / ODBIJ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _odbijKandidata(profil['id']),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("ODBIJ", style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _prihvatiKandidata(profil['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("PRIHVATI", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 40),
            
            // KONTAKT
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 20, color: Color(0xFF4A2C29)),
                const SizedBox(width: 10),
                Text(profil['telefon'] ?? "Nema broja", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}