import 'package:flutter/material.dart';
import '../dekor.dart';

class WebEkranOkvir extends StatelessWidget {
  final Widget child;
  final String? naslov;
  final double maxSirina;
  final bool pokaziPovratak;

  const WebEkranOkvir({
    super.key,
    required this.child,
    this.naslov,
    this.maxSirina = 780,
    this.pokaziPovratak = true,
  });

  static bool jeWeb(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 800;

  @override
  Widget build(BuildContext context) {
    if (!jeWeb(context)) {
      return child;
    }

    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Column(
      children: [
        if (naslov != null || pokaziPovratak)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: (boje.C ?? boje.B)?.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(
                  color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                if (pokaziPovratak)
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                    tooltip: 'Natrag',
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(
                          context,
                          '/ekrani/glavni_ekran',
                        );
                      }
                    },
                  ),
                if (pokaziPovratak && naslov != null) const SizedBox(width: 8),
                if (naslov != null)
                  Text(
                    naslov!,
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxSirina),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}