import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/jednostavni_ekran.dart';
import 'package:quickjobs/ekrani/glavni_ekran.dart'; 
import '../dekor.dart';
import 'opciUvjeti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostavkeEkran extends StatelessWidget {
  final bool dolaziIzJednostavnog;
  const PostavkeEkran({super.key, this.dolaziIzJednostavnog = false});

  // --- LOGIKA ZA BRISANJE PROFILA I RAČUNA ---
  void _obrisiRacun(BuildContext context) async {
    const tamnoSmedja = Color(0xFF4A2C29);
    const bojaPozadine = Color(0xFFE5D9D6);
    final supabase = Supabase.instance.client;

    bool? potvrda = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: bojaPozadine,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            const Text(
              "Brisanje računa", 
              style: TextStyle(color: tamnoSmedja, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: const Text(
          "Jeste li potpuno sigurni da želite obrisati svoj račun?\n\n"
          "Ova akcija je nepovratna i izbrisat će sve vaše podatke, oglase i recenzije.",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Odustani", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Briši račun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (potvrda == true) {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id; // Spremi ID prije odjave
    //briši korisnika pozivom funkcije iz supabasea
    await supabase.rpc('potpuno_obrisi_korisnika');
    // 1. Prvo napravi signOut da očistiš lokalne tokene i sesiju u aplikaciji
   
    await supabase.from('profiles').delete().eq('id', userId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vaš račun je uspješno i trajno obrisan."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  } catch (e) {
    debugPrint("Greška pri brisanju računa: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Greška pri brisanju: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
  }

  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, tamnoSmedja),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  children: [
                    // PRVA GRUPA: Općenito i način rada
                    _buildPostavkeGrupa([
                      _PostavkaItem(
                        ikona: dolaziIzJednostavnog 
                            ? Icons.dashboard_customize_rounded 
                            : Icons.auto_awesome_motion_rounded,
                        naslov: dolaziIzJednostavnog 
                            ? "Standardni način rada" 
                            : "Jednostavan način rada",
                        onTap: () {
                          if (dolaziIzJednostavnog) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const glavni_ekran()),
                              (route) => false,
                            );
                          } else {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const JednostavniIzbornik()),
                              (route) => false,
                            );
                          }
                        },
                        bojaTeksta: tamnoSmedja,
                      ),
                      _PostavkaItem(
                        ikona: Icons.description_outlined,
                        naslov: "Opći uvjeti korištenja",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UvjetiKoristenjaEkran()),
                          );
                        },
                      ),
                      // Zamijenjena odjava s brisanjem računa
                      _PostavkaItem(
                        ikona: Icons.delete_forever_rounded,
                        naslov: "Obriši moj račun",
                        onTap: () => _obrisiRacun(context),           
                        isZadnji: true,
                        bojaTeksta: Colors.red[700],
                        bojaIkone: Colors.red[700],
                      ),
                    ]),

                    const SizedBox(height: 25),

                    // DRUGA GRUPA: Izgled i personalizacija
                    _buildPostavkeGrupa([
                      _PostavkaItem(ikona: Icons.palette_outlined, naslov: "Promjena izgleda", onTap: () {}),
                      _PostavkaItem(ikona: Icons.grid_view_rounded, naslov: "Broj oglasa po stranici", onTap: () {}),
                      _PostavkaItem(ikona: Icons.format_size_rounded, naslov: "Veličina fonta", onTap: () {}),
                      _PostavkaItem(ikona: Icons.contrast_rounded, naslov: "Visok kontrast", onTap: () {}),
                      _PostavkaItem(
                        ikona: Icons.check_box_outlined, 
                        naslov: "Prihvaćene postavke", 
                        onTap: () {}, 
                        isZadnji: true
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color boja) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          Expanded(
            child: Text(
              "Postavke",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: boja),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPostavkeGrupa(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A2C29).withOpacity(0.3)),
      ),
      child: Column(children: items),
    );
  }
}

class _PostavkaItem extends StatelessWidget {
  final IconData ikona;
  final String naslov;
  final VoidCallback onTap;
  final bool isZadnji;
  final Color? bojaTeksta;
  final Color? bojaIkone;

  const _PostavkaItem({
    required this.ikona,
    required this.naslov,
    required this.onTap,
    this.isZadnji = false,
    this.bojaTeksta,
    this.bojaIkone,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Icon(ikona, color: bojaIkone ?? const Color(0xFF4A2C29), size: 24),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    naslov,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: bojaTeksta ?? Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26),
              ],
            ),
          ),
          if (!isZadnji)
            Divider(
              height: 1,
              indent: 60,
              endIndent: 20,
              color: const Color(0xFF4A2C29).withOpacity(0.1),
            ),
        ],
      ),
    );
  }
}