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
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(context, boje, isDark)
              : _buildMobileView(context, boje, isDark),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
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
                'QuickJobs',
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(boje.A!, isDark, isWeb: true),
                    const SizedBox(height: 22),
                    _buildGlavniDodajOglasGumb(context, boje),
                    const SizedBox(height: 28),
                    _buildIkoneGrid(context, boje, isWeb: true),
                  ],
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
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildLogo(boje.A!, isDark, isWeb: false),
          const SizedBox(height: 18),
          _buildGlavniDodajOglasGumb(context, boje),
          const SizedBox(height: 22),
          Expanded(
            child: Center(
              child: _buildIkoneGrid(context, boje, isWeb: false),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildIkoneGrid(
    BuildContext context,
    QuickJobsColors boje, {
    required bool isWeb,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: isWeb ? 28 : 24,
      crossAxisSpacing: isWeb ? 36 : 24,
      childAspectRatio: isWeb ? 1.85 : 1.15,
      children: [
        _buildVelikaTipka(
          context,
          ikona: Icons.settings_rounded,
          naslov: "Postavke",
          boje: boje,
          isWeb: isWeb,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const PostavkeEkran(dolaziIzJednostavnog: true),
            ),
          ),
        ),
        _buildVelikaTipka(
          context,
          ikona: Icons.account_box_rounded,
          naslov: "Profil",
          boje: boje,
          isWeb: isWeb,
          onTap: () =>
              Navigator.pushNamed(context, '/ekrani/korisnicki_profil'),
        ),
        _buildVelikaTipka(
          context,
          ikona: Icons.handyman_rounded,
          naslov: "Oglasi",
          boje: boje,
          isWeb: isWeb,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MojiOglasi()),
          ),
        ),
        _buildVelikaTipka(
          context,
          ikona: Icons.chat_bubble_rounded,
          naslov: "Poruke",
          boje: boje,
          isWeb: isWeb,
          onTap: () => Navigator.pushNamed(context, '/ekrani/chat_hub'),
        ),
      ],
    );
  }

  Widget _buildLogo(Color boja, bool isDark, {required bool isWeb}) {
    return Column(
      children: [
        SvgPicture.asset(
          isDark
              ? 'assets/images/logo_darkmode.svg'
              : 'assets/images/logo_lightmode.svg',
          width: isWeb ? 92 : 96,
          height: isWeb ? 92 : 96,
        ),
        const SizedBox(height: 10),
        Text(
          "QuickJobs",
          style: TextStyle(
            fontSize: isWeb ? 26 : 26,
            fontWeight: FontWeight.bold,
            color: boja,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVelikaTipka(
    BuildContext context, {
    required IconData ikona,
    required String naslov,
    required QuickJobsColors boje,
    required bool isWeb,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: boje.C,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikona, size: isWeb ? 56 : 52, color: boje.A),
            const SizedBox(height: 12),
            Text(
              naslov,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWeb ? 17 : 16,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlavniDodajOglasGumb(
    BuildContext context,
    QuickJobsColors boje,
  ) {
    return Card(
      elevation: 4,
      shadowColor: boje.A?.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: boje.A,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
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
                  color: boje.bg,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}