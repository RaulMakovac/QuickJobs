import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/jednostavni_ekran.dart';
import 'package:quickjobs/ekrani/glavni_ekran.dart'; // Uvezi svoj standardni početni ekran
import '../dekor.dart';
import 'opciUvjeti.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostavkeEkran extends StatelessWidget {
  // Ključni parametar koji određuje izgled i funkcionalnost prebacivanja moda
  final bool dolaziIzJednostavnog;
  const PostavkeEkran({super.key, this.dolaziIzJednostavnog = false});
void _odjava(BuildContext context) async {
  // Definiraj boje lokalno ili uvezi iz dekora
  const tamnoSmedja = Color(0xFF4A2C29);
  const bojaPozadine = Color(0xFFE5D9D6);

  bool? potvrda = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: bojaPozadine,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Odjava", 
        style: TextStyle(color: tamnoSmedja, fontWeight: FontWeight.bold)
      ),
      content: const Text("Jeste li sigurni da se želite odjaviti?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), 
          child: const Text("Odustani", style: TextStyle(color: Colors.black54))
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: const Text("Odjavi se", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (potvrda == true) {
    // Koristimo instancu supabasea (pazi da je uvezena ili dostupna)
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
                        // Dinamička ikona i naslov ovisno o trenutnom modu
                        ikona: dolaziIzJednostavnog 
                            ? Icons.dashboard_customize_rounded 
                            : Icons.auto_awesome_motion_rounded,
                        naslov: dolaziIzJednostavnog 
                            ? "Standardni način rada" 
                            : "Jednostavan način rada",
                        onTap: () {
                          if (dolaziIzJednostavnog) {
                            // Vraćamo se na standardni glavni ekran
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const glavni_ekran()),
                              (route) => false,
                            );
                          } else {
                            // Idemo na jednostavni izbornik
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
                      _PostavkaItem(
                        ikona: Icons.logout_rounded,
                        naslov: "Odjava",
                        onTap: () => _odjava(context),           
                        isZadnji: true,
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

  const _PostavkaItem({
    required this.ikona,
    required this.naslov,
    required this.onTap,
    this.isZadnji = false,
    this.bojaTeksta,
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
                Icon(ikona, color: const Color(0xFF4A2C29), size: 24),
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