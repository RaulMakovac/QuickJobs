import 'package:flutter/material.dart';
import 'moji_oglasi.dart'; 
import 'moje_prijave.dart';
import '../dekor.dart';

class MojiPosloviHub extends StatelessWidget {
  const MojiPosloviHub({super.key});

  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);
  static const cardColor = Color(0xFF8F6E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Zadržavamo normalnu boju pozadine Scaffold-a
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // AppBar mora ostati transparentan da ne prekrije gornji krug
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Moji poslovi",
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      // 2. Ovdje ubacujemo krugove kao bazu za body
      body: PozadinaKrugovi(
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
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
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}