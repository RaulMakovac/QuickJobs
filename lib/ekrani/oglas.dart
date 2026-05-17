import 'package:flutter/material.dart';
import '/ekrani/glavni_ekran.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart';
import '/ekrani/korisnicki_profil.dart';

class DetaljiOglasa extends StatelessWidget {
  final Oglas oglas;
  final bool samoPregled;

  const DetaljiOglasa({
    super.key,
    required this.oglas,
    this.samoPregled = false, // Default je false da se gumb vidi na glavnom ekranu
  });

  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);
  static const cardColor = Color(0xFF8F6E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 200),
            child: Column(
              children: [
                _buildAppBar(context),
                const SizedBox(height: 35),
                _buildJobTitleHeader(),
                
                // --- KONTROLIRANI RAZMAK I BANER ---
                if (oglas.jeReportan) ...[
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50]!.withOpacity(0.85), // Svjetlija pozadina koja odskače
                      border: Border.all(color: Colors.redAccent, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Ikona ostaje gore ako je tekst dug
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upozorenje zajednice",
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Ovaj oglas je reportan od strane zajednice zbog sumnje na kršenje pravila ili prijevaru. Postupajte s oprezom!",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 25), // Ujednačen razmak prije autora
                _buildAuthorSection(context),

                const SizedBox(height: 25), // Ujednačen razmak prije detalja
                _buildDetailRow('Adresa: ${oglas.adresa}'),
                const SizedBox(height: 12),
                _buildDetailRow('Isplata: ${oglas.isplata}€'),
                
                const SizedBox(height: 25),
                _buildDescriptionCard(),

                const SizedBox(height: 45),

                // --- UVJETNI PRIKAZ GUMBA ---
                if (samoPregled)
                  const Column(
                    children: [
                      Icon(Icons.info_outline, color: darkBrown, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Pregled aktivne prijave',
                        style: TextStyle(
                          color: darkBrown,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                else
                  _buildApplyButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SEKCIJA AUTORA (Uređena u obliku čiste kartice) ---
  Widget _buildAuthorSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (oglas.autorId != null && oglas.autorId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  KorisnickiProfil(prikazaniKorisnikId: oglas.autorId),
            ),
          );
        } else {
          _showSnack(context, "Profil autora nije dostupan.", isError: true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.15), // Blago prozirna smeđa podloga koja odgovara dizajnu
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            _buildSquareImage(),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle, size: 30, color: darkBrown),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          oglas.autorIme ?? 'Nepoznat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 38),
                    child: Text(
                      'UVID U PROFIL POSLODAVCA',
                      style: TextStyle(
                        color: cardColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: darkBrown, size: 18), // Mali indikator da se može kliknuti
          ],
        ),
      ),
    );
  }

  // --- GUMB ZA PRIJAVU ---
  Widget _buildApplyButton(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handlePrijava(context),
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.check, size: 55, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Prijavi se na posao!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // --- LOGIKA PRIJAVE NA POSAO ---
  Future<void> _handlePrijava(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showSnack(context, 'Morate biti prijavljeni!', isError: true);
      return;
    }

    try {
      await supabase.from('prijave').insert({
        'oglas_id': oglas.id,
        'korisnik_id': user.id,
      });

      if (context.mounted) {
        _showSnack(context, 'Uspješno prijavljeni!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(
          context,
          'Već ste prijavljeni ili je došlo do greške.',
          isError: true,
        );
      }
    }
  }

  // --- POMOĆNI DIZAJN ---
  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 30),
        ),
        const Text(
          'Opis oglasa',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(
            Icons.flag_outlined,
            color: Colors.redAccent,
            size: 30,
          ),
          tooltip: "Prijavi oglas",
          onPressed: () {
            _prikaziDijalogZaPrijavuOglasa(context, oglas.id);
          },
        ),
      ],
    );
  }

  Widget _buildJobTitleHeader() {
    return Container(
      width: double.infinity, // Raširi naslov preko cijele širine radi simetrije
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: darkBrown,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        oglas.naslov,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Detaljni opis posla:",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            oglas.opis.isEmpty ? 'Nema opisa.' : oglas.opis,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSquareImage() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.image, color: Colors.white, size: 30),
    );
  }

  Widget _buildDetailRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  // --- POP-UP DIJALOG ZA REPORT OGLASA ---
  void _prikaziDijalogZaPrijavuOglasa(BuildContext context, String oglasId) {
    String odabraniRazlog = "Scam / Prijevara";
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Prijavi oglas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Odaberite razlog zašto prijavljujete ovaj oglas:"),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: odabraniRazlog,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  "Scam / Prijevara",
                  "Lažni oglas",
                  "Neprimjeren sadržaj",
                  "Ostalo",
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setDialogState(() => odabraniRazlog = v!),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: komentarController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Opišite detaljnije (opcionalno)...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
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
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                try {
                  await Supabase.instance.client.from('reports').insert({
                    'prijavitelj_id': user.id,
                    'oglas_id': oglasId,
                    'razlog': odabraniRazlog,
                    'komentar': komentarController.text,
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // Zatvori dijalog
                    Navigator.pop(context); // Vrati korisnika na listu
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Oglas prijavljen. Hvala na povratnoj informaciji!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Greška pri slanju reporta: $e");
                }
              },
              child: const Text(
                "Pošalji",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}