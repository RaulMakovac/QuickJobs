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

    return Scaffold(
      backgroundColor: boje.bg, // 1. boja za pozadinu ekrana
      body: PozadinaKrugovi(
        krugBoja: boje.C, // Proslijeđujemo boju C u globalni sustav krugova
        child: SafeArea(
          child: Padding(
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
                ElevatedButton(
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
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}