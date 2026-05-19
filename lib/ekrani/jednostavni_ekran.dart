import 'package:flutter/material.dart';
import '../dekor.dart';
import 'postavke.dart';
import 'moji_oglasi.dart';
import '../banProvjera.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JednostavniIzbornik extends StatefulWidget {
  const JednostavniIzbornik({super.key});

  @override
  State<JednostavniIzbornik> createState() => _JednostavniIzbornikState();
}

class _JednostavniIzbornikState extends State<JednostavniIzbornik> {
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final banPoruka = await AuthProvjera.ProvjeriBanKorisnika();
      if (banPoruka != null && mounted) {
        AuthProvjera.prikaziBanDialog(context, banPoruka);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);
    const bojaIkone = Color(0xFF63403C);
    const bojaPozadineIkone = Color(0xFFD9C5C1);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // LOGO SEKCIJA (Gornji dio ekrana)
                _buildLogo(tamnoSmedja),
                
                // SREDIŠNJI DIO - Sve je centrirano i nema skrolanja
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2x2 Grid za osnovne opcije
                      GridView.count(
                        shrinkWrap: true, // Omogućuje gridu da zauzme samo onoliko mjesta koliko mu treba
                        physics: const NeverScrollableScrollPhysics(), // GASI SCROLLANJE
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1, // Blago pravokutni oblik za moderniji izgled
                        children: [
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.settings_rounded,
                            naslov: "Postavke",
                            boja: bojaIkone,
                            pozadina: bojaPozadineIkone,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostavkeEkran(dolaziIzJednostavnog: true,))),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.person_rounded,
                            naslov: "Moj profil",
                            boja: bojaIkone,
                            pozadina: bojaPozadineIkone,
                            onTap: () => Navigator.pushNamed(context, '/ekrani/korisnicki_profil'),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.chat_bubble_rounded,
                            naslov: "Poruke",
                            boja: bojaIkone,
                            pozadina: bojaPozadineIkone,
                            onTap: () => Navigator.pushNamed(context, '/ekrani/chat_hub'),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.handyman_rounded,
                            naslov: "Moji oglasi",
                            boja: bojaIkone,
                            pozadina: bojaPozadineIkone,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MojiOglasi())),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // RESTRUKTURIRANI GUMB: Široka, istaknuta kartica za dodavanje oglasa
                      _buildGlavniDodajOglasGumb(context, tamnoSmedja),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _buildLogo(Color boja) {
  return Column(
    children: [
      // Prikaz tvog novog SVG logotipa iz Figme
      SvgPicture.asset(
        'assets/images/QJ_Logo.svg', // Putanja do datoteke koju si definirao u pubspec.yaml
        width: 100,             // Prilagodi veličinu (visinu i širinu) po želji
        height: 100,
        
        
      ),
      const SizedBox(height: 14),
      Text(
        "QuickJobs",
        style: TextStyle(
          fontSize: 26, 
          fontWeight: FontWeight.bold, 
          color: boja, 
          letterSpacing: 1.5,
        ),
      ),
    ],
  );
}

  Widget _buildVelikaTipka(BuildContext context, {
    required IconData ikona,
    required String naslov,
    required Color boja,
    required Color pozadina,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: pozadina.withOpacity(0.9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikona, size: 44, color: boja),
            const SizedBox(height: 12),
            Text(
              naslov,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: boja),
            ),
          ],
        ),
      ),
    );
  }

  // NOVI DIZAJN: Široka horizontalna kartica koja spaja vizualni prostor na dnu grida
  Widget _buildGlavniDodajOglasGumb(BuildContext context, Color boja) {
    return Card(
      elevation: 4,
      shadowColor: boja.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: boja,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 30, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "Objavi novi oglas",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  letterSpacing: 0.5
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}