import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../dekor.dart';

class intro extends StatelessWidget {
  const intro({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Dohvaćamo tvoju paletu boja i provjeravamo aktivni mod teme
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg, // 1. boja za pozadinu ekrana
      body: PozadinaKrugovi(
        krugBoja: boje.C, // Proslijeđujemo boju C u globalni sustav krugova
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            decoration: BoxDecoration(
              color: boje.bg?.withValues(alpha: 0.88),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  isDark
                      ? 'assets/images/intro_darkmode.svg'
                      : 'assets/images/intro_lightmode.svg',
                  height: 230,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  'Brzo i lako pronađite izvor zarade ili radnika uz QuickJobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: boje.A,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Mjesto gdje ponuda i potražnja za privremenim poslovima postaju jednostavne. Bilo da hitno trebate obaviti zadatak ili tražite fleksibilnu priliku za zaradu, QuickJobs vam omogućuje siguran pronalazak idealnog spoja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.normal,
                    color: boje.A?.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 32),
                _buildStartButton(context, boje),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Ilustracija koja se mijenja ovisno o Light/Dark modu
          SvgPicture.asset(
            isDark
                ? 'assets/images/intro_darkmode.svg'
                : 'assets/images/intro_lightmode.svg',
            height: MediaQuery.of(context).size.height * 0.35,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 40),

          // Naslov
          Text(
            'Brzo i lako pronađite izvor zarade ili radnika uz QuickJobs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: boje.A,
            ),
          ),
          const SizedBox(height: 30),

          // Podnaslov
          Text(
            'Mjesto gdje ponuda i potražnja za privremenim poslovima postaju jednostavne. Bilo da hitno trebate obaviti zadatak ili tražite fleksibilnu priliku za zaradu, QuickJobs vam omogućuje siguran pronalazak idealnog spoja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: boje.A,
            ),
          ),

          const Spacer(flex: 3),

          // Gumb
          _buildStartButton(context, boje),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, QuickJobsColors boje) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/ekrani/registracija');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: boje.A,
        foregroundColor: boje.bg,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: const Text('Započnite', style: TextStyle(fontSize: 18)),
    );
  }
}