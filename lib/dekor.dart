import 'package:flutter/material.dart';

// --- SUSTAV BOJA I TEMA (ThemeExtension) ---
class QuickJobsColors extends ThemeExtension<QuickJobsColors> {
  final Color? bg;
  final Color? A;
  final Color? B;
  final Color? C;

  const QuickJobsColors({
    required this.bg,
    required this.A,
    required this.B,
    required this.C,
  });

  @override
  QuickJobsColors copyWith({
    Color? bg,
    Color? A,
    Color? B,
    Color? C,
  }) {
    return QuickJobsColors(
      bg: bg ?? this.bg,
      A: A ?? this.A,
      B: B ?? this.B,
      C: C ?? this.C,
    );
  }

  @override
  QuickJobsColors lerp(ThemeExtension<QuickJobsColors>? other, double t) {
    if (other is! QuickJobsColors) return this;
    return QuickJobsColors(
      bg: Color.lerp(bg, other.bg, t),
      A: Color.lerp(A, other.A, t),
      B: Color.lerp(B, other.B, t),
      C: Color.lerp(C, other.C, t),
    );
  }
}

// --- SVIJETLA TEMA ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF0DDDC),
  extensions: const <ThemeExtension<dynamic>>[
    QuickJobsColors(
      bg: Color(0xFFF0DDDC),        // 1. boja
      A: Color(0xFF4A2727),         // 2. boja
      B: Color(0xFFB08E87),         // 3. boja
      // Ovdje stavi boju C za light mode i odmah joj smanji opacity po želji (npr. 0.4 ili 0.5)
      C: Color(0xFFCFB1AC),         
    ),
  ],
);

// --- TAMNA TEMA ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2A221B),
  extensions: const <ThemeExtension<dynamic>>[
    QuickJobsColors(
      bg: Color(0xFF2A221B),        // 1. boja
      A: Color(0xFFD4B493),         // 2. boja
      B: Color(0xFF4B3D35),         // 3. boja
      // Ovdje stavi boju C za dark mode i dajte joj opacity (npr. 0.25 da budu suptilni)
      C: Color(0xFF5D463B),         
    ),
  ],
);

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// --- POZADINA S KRUGOVIMA ---
class PozadinaKrugovi extends StatelessWidget {
  final Widget child;
  final Color? krugBoja;

  const PozadinaKrugovi({
    super.key,
    required this.child,
    this.krugBoja,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<QuickJobsColors>();
    
  
    final osnovnaBoja = krugBoja ?? themeColors?.C ?? const Color(0xFFCFB1AC);
    

    final aktivnaBojaKruga = osnovnaBoja.withValues(alpha: 0.4); 

    return Stack(
      children: [
        // Gornji lijevi krug
        Positioned(
          top: -120,
          left: -100,
          child: CustomPaint(
            size: const Size(280, 280),
            painter: _CirclePainter(color: aktivnaBojaKruga),
          ),
        ),
        // Gornji desni krug
        Positioned(
          top: -120,
          right: -100,
          child: CustomPaint(
            size: const Size(200, 200),
            painter: _CirclePainter(color: aktivnaBojaKruga),
          ),
        ),
        // Donji desni krug
        Positioned(
          bottom: -120,
          right: -50,
          child: CustomPaint(
            size: const Size(300, 300),
            painter: _CirclePainter(color: aktivnaBojaKruga),
          ),
        ),
        child,
      ],
    );
  }
}

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

// --- MAPA KATEGORIJA I IKONA ---
final Map<String, IconData> kategorijeSaIkonama = {
  "Fizički poslovi": Icons.construction_rounded,
  "Pet/Babysitting": Icons.child_care_rounded,
  "Jednostavne usluge": Icons.volunteer_activism_rounded,
  "Instrukcije": Icons.school_rounded,
  "Ostalo": Icons.more_horiz_rounded,
};