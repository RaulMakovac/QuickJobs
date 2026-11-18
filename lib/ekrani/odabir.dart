import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../dekor.dart'; // Uvoz centraliziranih boja i teme

class odabir extends StatelessWidget {
  const odabir({super.key});

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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),                                        
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 26,
                        color: boje.A,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // NASLOV
                Text(
                  'Dobrodošli!',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: boje.A,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Molimo vas da odaberete tražite li posao ili radnika',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: boje.A?.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 60),

                // KARTICE ZA ODABIR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCard(
                      context,
                      title: 'Tražim radnika',
                      svgPath: 'assets/images/trazim_radnika.svg',
                      boje: boje,
                      onTap: () {
                        Navigator.pushNamed(context, '/ekrani/jednostavni_ekran');
                      },
                    ),
                    _buildRoleCard(
                      context,
                      title: 'Tražim posao',
                      svgPath: 'assets/images/trazim_posao.svg',
                      boje: boje,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/ekrani/glavni_ekran',
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),

                // DONJA ILUSTRACIJA
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SvgPicture.asset(
                    'assets/images/upitnik.svg', 
                    height: 180,
                    placeholderBuilder: (context) => SizedBox(
                      height: 180,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: boje.C,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Funkcija za izgradnju pojedinačne kartice 
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String svgPath,
    required QuickJobsColors boje,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: boje.C?.withValues(alpha: 0.3),  
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: boje.B!, width: 2), // Rub koristi boju B
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SvgPicture.asset(
                svgPath,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => Container(
                  color: boje.bg,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: boje.B,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: boje.A,
            ),
          ),
        ],
      ),
    );
  }
}
