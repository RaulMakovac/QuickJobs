import 'package:flutter/material.dart';
import 'moji_oglasi.dart'; 
import 'moje_prijave.dart';

class MojiPosloviHub extends StatelessWidget {
  const MojiPosloviHub({super.key});

  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Moji poslovi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSelectionCard(
              context,
              title: "Moji objavljeni oglasi",
              subtitle: "Pregledaj i upravljaj poslovima koje si ti objavio",
              icon: Icons.list_alt,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MojiOglasi())),
            ),
            const SizedBox(height: 20),
            _buildSelectionCard(
              context,
              title: "Moje prijave",
              subtitle: "Pogledaj status poslova na koje si se prijavio",
              icon: Icons.assignment_turned_in,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MojePrijaveEkran())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF8F6E68),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}