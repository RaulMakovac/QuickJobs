import 'package:flutter/material.dart';
import '../dekor.dart';
import 'postavke.dart';
import 'moji_oglasi.dart';
// Uvezi ostale potrebne ekrane (ChatHub, Profil, DodajOglas...)

class JednostavniIzbornik extends StatelessWidget {
  const JednostavniIzbornik({super.key});

  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);
    const bojaIkone = Color(0xFF63403C);
    const bojaPozadineIkone = Color(0xFFD9C5C1);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // LOGO SEKCIJA (Povećalo s čekićem iz tvog dizajna)
              _buildLogo(tamnoSmedja),
              const SizedBox(height: 50),
              
              // GRID S IKONAMA
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  crossAxisCount: 2, // Dva stupca
                  mainAxisSpacing: 30,
                  crossAxisSpacing: 30,
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
                      ikona: Icons.gavel_rounded, // Ili Icons.engineering_rounded
                      naslov: "Moji oglasi",
                      boja: bojaIkone,
                      pozadina: bojaPozadineIkone,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MojiOglasi())),
                    ),
                  ],
                ),
              ),
              
              // ISTAKNUTA TIPKA ZA DODAVANJE OGLASA (Dno)
              _buildDodajOglasGumb(context, tamnoSmedja),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color boja) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: boja, width: 3),
          ),
          child: Icon(Icons.search_rounded, size: 60, color: boja),
        ),
        const SizedBox(height: 10),
        Text(
          "QuickJobs",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: boja, letterSpacing: 1.2),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: pozadina.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikona, size: 55, color: boja),
            const SizedBox(height: 10),
            Text(
              naslov,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: boja),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDodajOglasGumb(BuildContext context, Color boja) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: boja,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: boja.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.add, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            "Dodaj oglas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: boja),
          ),
        ],
      ),
    );
  }
}