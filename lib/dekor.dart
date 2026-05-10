import 'package:flutter/material.dart';

class PozadinaKrugovi extends StatelessWidget {
  final Widget child;
  final Color krugBoja;

  const PozadinaKrugovi({
    super.key,
    required this.child,
    this.krugBoja = const Color(0xFFD6C8C5), // Defaultna boja koju koristiš
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gornji lijevi krug
        Positioned(
          top: -120,
          left: -100,
          child: CustomPaint(
            size: const Size(280, 280),
            painter: _CirclePainter(color: krugBoja),
          ),
        ),

         Positioned(
          top: -120,
          right: -100,
          child: CustomPaint(
            size: const Size(200, 200),
            painter: _CirclePainter(color: krugBoja),
          ),
        ),
        // Donji desni krug
        Positioned(
          bottom: -120,
          right: -50,
          child: CustomPaint(
            size: const Size(300, 300),
            painter: _CirclePainter(color: krugBoja),
          ),
        ),
        // Sadržaj ekrana koji dolazi "iznad" krugova
        child,
      ],
    );
  }
}

// Painter je sada privatan (sa donjom crtom _) jer se koristi samo unutar ove datoteke
class _CirclePainter extends CustomPainter {
  final Color color;
  _CirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}