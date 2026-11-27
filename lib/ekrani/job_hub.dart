import 'package:flutter/material.dart';
import 'moji_oglasi.dart';
import 'moje_prijave.dart';
import '../dekor.dart';

class MojiPosloviHub extends StatelessWidget {
  const MojiPosloviHub({super.key});

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      extendBodyBehindAppBar: !jeWeb,
      appBar: jeWeb
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: boje.A),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Moji poslovi",
                style: TextStyle(
                  color: boje.A,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              centerTitle: true,
            ),
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(context, boje, isDark)
              : _buildMobileView(context, boje),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
  ) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.08)
        : (boje.A ?? Colors.black).withValues(alpha: 0.10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: (boje.C ?? boje.B)?.withValues(alpha: 1.0),
            border: Border(
              bottom: BorderSide(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                tooltip: 'Natrag',
              ),
              const SizedBox(width: 12),
              Text(
                'Moji poslovi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: boje.A,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 72).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: boxPozadina,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: (boje.A ?? Colors.black).withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            ),
                          ),
                        ),
                        child: _buildKartice(context, boje),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildKartice(context, boje),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildKartice(BuildContext context, QuickJobsColors boje) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectionCard(
          context,
          title: "Moji objavljeni oglasi",
          subtitle: "Upravljaj poslovima koje si objavio",
          icon: Icons.list_alt_rounded,
          boje: boje,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MojiOglasi()),
          ),
        ),
        const SizedBox(height: 25),
        _buildSelectionCard(
          context,
          title: "Moje prijave",
          subtitle: "Status poslova na koje si se prijavio",
          icon: Icons.assignment_turned_in_rounded,
          boje: boje,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MojePrijaveEkran()),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required QuickJobsColors boje,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: boje.C,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: boje.A!.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: boje.A),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: boje.A?.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}