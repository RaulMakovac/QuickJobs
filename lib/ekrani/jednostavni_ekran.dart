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
    // Dohvaćamo definirane boje iz dekor.dart
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C, // Koristi globalni sustav krugova
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildLogo(boje.A!),
                
                // SREDIŠNJI DIO - Sve je centrirano i nema skrolanja
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GridView.count(
                        shrinkWrap: true, // Omogućuje gridu da zauzme samo onoliko mjesta koliko mu treba
                        physics: const NeverScrollableScrollPhysics(), // GASI SCROLLANJE
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 1.1, 
                        children: [
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.settings_rounded,
                            naslov: "Postavke",
                            boje: boje,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostavkeEkran(dolaziIzJednostavnog: true))),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.person_rounded,
                            naslov: "Moj profil",
                            boje: boje,
                            onTap: () => Navigator.pushNamed(context, '/ekrani/korisnicki_profil'),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.chat_bubble_rounded,
                            naslov: "Poruke",
                            boje: boje,
                            onTap: () => Navigator.pushNamed(context, '/ekrani/chat_hub'),
                          ),
                          _buildVelikaTipka(
                            context,
                            ikona: Icons.handyman_rounded,
                            naslov: "Moji oglasi",
                            boje: boje,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MojiOglasi())),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildGlavniDodajOglasGumb(context, boje),
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
        SvgPicture.asset(
          'assets/images/QJ_Logo.svg', 
          width: 100,             
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
    required QuickJobsColors boje,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: boje.C, // Kartice koriste boju C
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikona, size: 44, color: boje.A),
            const SizedBox(height: 12),
            Text(
              naslov,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: boje.A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlavniDodajOglasGumb(BuildContext context, QuickJobsColors boje) {
    return Card(
      elevation: 4,
      shadowColor: boje.A?.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: boje.A, // Glavni gumb koristi boju A
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 30, color: boje.bg),
              const SizedBox(width: 12),
              Text(
                "Objavi novi oglas",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: boje.bg, // Tekst koristi boju bg za kontrast
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