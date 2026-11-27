import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart'; // Uvoz centraliziranih boja i teme

class odabir extends StatelessWidget {
  const odabir({super.key});

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    final String trazimRadnikaSvg = isDarkMode
        ? 'assets/images/trazimradnika_darkmode.svg'
        : 'assets/images/trazimradnika_lightmode.svg';
    final String trazimPosaoSvg = isDarkMode
        ? 'assets/images/trazimposao_darkmode.svg'
        : 'assets/images/trazimposao_lightmode.svg';
    final String upitnikSvg = isDarkMode
        ? 'assets/images/upitnik_darkmode.svg'
        : 'assets/images/upitnik_lightmode.svg';

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(
                  context,
                  boje,
                  isDarkMode,
                  trazimRadnikaSvg,
                  trazimPosaoSvg,
                  upitnikSvg,
                )
              : _buildMobileView(
                  context,
                  boje,
                  isDarkMode,
                  trazimRadnikaSvg,
                  trazimPosaoSvg,
                  upitnikSvg,
                ),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDarkMode,
    String trazimRadnikaSvg,
    String trazimPosaoSvg,
    String upitnikSvg,
  ) {
    final Color boxPozadina = isDarkMode
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
                'Odabir uloge',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: boxPozadina,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (boje.A ?? Colors.black).withValues(
                        alpha: isDarkMode ? 0.18 : 0.12,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderSection(boje, isWeb: true),
                      const SizedBox(height: 40),
                      _buildRoleRow(
                        context,
                        boje,
                        isDarkMode,
                        trazimRadnikaSvg,
                        trazimPosaoSvg,
                      ),
                      const SizedBox(height: 32),
                      SvgPicture.asset(
                        upitnikSvg,
                        height: 130,
                        placeholderBuilder: (context) => SizedBox(
                          height: 130,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: 45,
                              color: boje.C,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDarkMode,
    String trazimRadnikaSvg,
    String trazimPosaoSvg,
    String upitnikSvg,
  ) {
    return Padding(
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
          _buildHeaderSection(boje, isWeb: false),
          const SizedBox(height: 60),
          _buildRoleRow(
            context,
            boje,
            isDarkMode,
            trazimRadnikaSvg,
            trazimPosaoSvg,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: SvgPicture.asset(
              upitnikSvg,
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
    );
  }

  Widget _buildHeaderSection(QuickJobsColors boje, {required bool isWeb}) {
    return Column(
      children: [
        Text(
          'Dobrodošli!',
          style: TextStyle(
            fontSize: isWeb ? 36 : 42,
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
      ],
    );
  }

  Widget _buildRoleRow(
    BuildContext context,
    QuickJobsColors boje,
    bool isDarkMode,
    String trazimRadnikaSvg,
    String trazimPosaoSvg,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoleCard(
          context,
          title: 'Tražim radnika',
          svgPath: trazimRadnikaSvg,
          boje: boje,
          isDarkMode: isDarkMode,
          onTap: () async {
            // Spremamo ulogu u Supabase user metadata
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              await Supabase.instance.client.auth.updateUser(
                UserAttributes(data: {'uloga': 'poslodavac'}),
              );
            }
            if (context.mounted) {
              Navigator.pushNamed(context, '/ekrani/jednostavni_ekran');
            }
          },
        ),
        _buildRoleCard(
          context,
          title: 'Tražim posao',
          svgPath: trazimPosaoSvg,
          boje: boje,
          isDarkMode: isDarkMode,
          onTap: () async {
            // Spremamo ulogu u Supabase user metadata
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              await Supabase.instance.client.auth.updateUser(
                UserAttributes(data: {'uloga': 'kandidat'}),
              );
            }
            if (context.mounted) {
              Navigator.pushNamed(context, '/ekrani/glavni_ekran');
            }
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String svgPath,
    required QuickJobsColors boje,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    final Color karticaPozadina = isDarkMode
        ? (boje.bg ?? Colors.black).withValues(alpha: 0.80)
        : (boje.bg ?? Colors.white).withValues(alpha: 0.92);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: karticaPozadina,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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