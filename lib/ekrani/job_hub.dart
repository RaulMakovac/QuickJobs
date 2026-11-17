import 'package:flutter/material.dart';
import 'moji_oglasi.dart'; 
import 'moje_prijave.dart';
import '../dekor.dart';

class MojiPosloviHub extends StatelessWidget {
  const MojiPosloviHub({super.key});

  @override
  Widget build(BuildContext context) {
    // Dohvaćamo definirane boje iz dekor.dart
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // AppBar mora ostati transparentan da ne prekrije gornji krug
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: boje.A),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Moji poslovi",
          style: TextStyle(color: boje.A, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSelectionCard(
                  context,
                  title: "Moji objavljeni oglasi",
                  subtitle: "Upravljaj poslovima koje si objavio",
                  icon: Icons.list_alt_rounded,
                  boje: boje,
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const MojiOglasi())
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
                    MaterialPageRoute(builder: (context) => const MojePrijaveEkran())
                  ),
                ),
                const SizedBox(height: 60), // Malo razmaka do dna
              ],
            ),
          ),
        ),
      ),
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
            Icon(Icons.arrow_forward_ios, color: boje.A?.withValues(alpha: 0.7), size: 18),
          ],
        ),
      ),
    );
  }
}