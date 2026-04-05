import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 

class intro extends StatelessWidget {
  const intro ({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE5D9D6);
    const primaryTextColor = Color(0xFF2E2E2E);
    const accentColor = Color(0xFF8C5353);
    const circleColor = Color(0xFFD6C8C5);



  return Scaffold(
    backgroundColor: backgroundColor,
    body: Stack(
      children: [
        // 1. KRUGOVI )
        Positioned(
          top: -60, 
          left: -60,
          child: CustomPaint(
            size: const Size(200, 200),
            painter: CirclePainter(color: circleColor),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -40,
          child: CustomPaint(
            size: const Size(250, 250),
            painter: CirclePainter(color: circleColor),
          ),
        ),

        // 2. SADRŽAJ 
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Ilustracija
                SvgPicture.asset(
                  'assets/images/intro.svg',
                  height: MediaQuery.of(context).size.height * 0.35,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Tekst
                const Text(
                  'Brzo i lako pronađite izvor zarade ili radnika uz QuickJobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 30),
                // Tekst
                const Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean dui arcu, dapibus in dui eu, tincidunt ullamcorper lacus. Donec molestie ex ut erat ultricies feugiat. Pellentesque at vehicula dolor, finibus tristique ligula',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: primaryTextColor,
                  ),
                ),
                
                const Spacer(flex: 3),

                // Gumb
                ElevatedButton(
                  onPressed: () {
                // Navigator.pushNamed šalje korisnika na registraciju
                  Navigator.pushNamed(context, '/ekrani/registracija');
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Započnite', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20), // Mali razmak od dna SafeAree
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
// --- POMOĆNA KLASA ZA CRTANJE KRUGA ---
class CirclePainter extends CustomPainter {
  final Color color;

  CirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Crtamo krug u središtu zadanog Size-a s radijusom koji odgovara širini
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Krug se ne mijenja, pa ga ne treba ponovno crtati
  }
}