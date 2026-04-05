import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class odabir extends StatelessWidget {
  const odabir({super.key});

  // Boje usklađene s ostatkom aplikacije
  static const backgroundColor = Color(0xFFE5D9D6);
  static const circleColor = Color(0xFFD6C8C5);
  static const darkBrownColor = Color(0xFF6D3F3A);
  static const textColor = Color(0xFF2E2E2E);
  static const cardBorderColor = Color(0xFF8F6E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // POZADINSKI KRUGOVI
          Positioned(top: -50, left: -50, child: _CircleCustom(size: 200)),
          Positioned(top: 50, left: -80, child: _CircleCustom(size: 250)),
          Positioned(bottom: -100, right: -50, child: _CircleCustom(size: 300)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Gumb natrag
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // NASLOV
                  const Text(
                    'Dobrodošli!',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Molimo vas da odaberete tražite li posao ili radnika',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5A5A),
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
                        onTap: () {
                          // Vodi na novi ekran s oglasima
                          Navigator.pushNamed(context, '/ekrani/glavni_ekran');
                        },
                      ),
                      _buildRoleCard(
                        context,
                        title: 'Tražim posao',
                        svgPath: 'assets/images/trazim_posao.svg',
                        onTap: () {
                          // Također vodi na isti ekran (ili neki drugi ako želiš)
                          Navigator.pushNamed(context, '/ekrani/glavni_ekran');
                        },
                      ),
                    ],
                  ),
                  const Spacer(),

                  // DONJA ILUSTRACIJA
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: SvgPicture.asset(
                      'assets/images/upitnik.svg', // <-- OVDJE UBACI DONJI SVG
                      height: 180,
                      placeholderBuilder: (context) => const SizedBox(
                        height: 180,
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: circleColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Funkcija za izgradnju pojedinačne kartice (Role Card)
  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String svgPath,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: cardBorderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                // Placeholder dok ne ubaciš prave fileove da ti se ne ruši app
                placeholderBuilder: (context) => Container(
                  color: backgroundColor,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: cardBorderColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Pomoćni widget za krugove u pozadini
class _CircleCustom extends StatelessWidget {
  final double size;
  const _CircleCustom({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFD6C8C5),
        shape: BoxShape.circle,
      ),
    );
  }
}
