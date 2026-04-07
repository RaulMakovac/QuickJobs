import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quickjobs/ekrani/oglas.dart';
import 'korisnicki_profil.dart';

class Oglas {
  final String id;
  final String naslov;
  final String opis;
  final String isplata;
  final String adresa;
  final String status;
  final String? autorIme;
  final DateTime createdAt;

  Oglas({
    required this.id,
    required this.naslov,
    required this.opis,
    required this.isplata,
    required this.adresa,
    required this.status,
    this.autorIme,
    required this.createdAt,
  });

  factory Oglas.fromJson(Map<String, dynamic> json) {
    final profileData = json['autor'];
    return Oglas(
      id: json['id'] ?? '',
      naslov: json['naslov'] ?? 'Bez naslova',
      opis: json['opis'] ?? '',
      isplata: json['isplata']?.toString() ?? '0',
      adresa: json['adresa'] ?? '',
      status: json['status'] ?? 'otvoren',
      createdAt: DateTime.parse(json['created_at']),
      autorIme: profileData != null
          ? profileData['puno_ime']
          : 'Nepoznat autor',
    );
  }
}

class glavni_ekran extends StatefulWidget {
  const glavni_ekran({super.key});

  @override
  State<glavni_ekran> createState() => _glavni_ekranState();
}

class _glavni_ekranState extends State<glavni_ekran> {
  final supabase = Supabase.instance.client;

  static const bgColor = Color(0xFFE5D9D6);
  static const cardColor = Color(0xFF8F6E68);
  static const searchBarColor = Color(0xFFD1BDB9);
  static const darkBrown = Color(0xFF4A2C29);
  static const footerColor = Color(0xFF8F6E68);

  Future<List<Oglas>> dohvatiOglase() async {
    try {
      final response = await supabase
          .from('oglasi')
          .select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime)')
          .order('created_at', ascending: false);

      final List data = response as List;
      return data.map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      print("DEBUG GREŠKA: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Postavke (lijevo)
                  const Icon(Icons.settings, size: 35, color: darkBrown),

                  _buildCentralLogo(),

                  // Profil (desno) s funkcijom tipke
                  IconButton(
                    icon: const Icon(
                      Icons.account_box,
                      size: 35,
                      color: darkBrown,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KorisnickiProfil(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: searchBarColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.black54),
                    border: InputBorder.none,
                    hintText: 'Pretraži...',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- LISTA OGLASA ---
            Expanded(
              child: FutureBuilder<List<Oglas>>(
                future: dohvatiOglase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: darkBrown),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Trenutno nema oglasa."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildOglasCard(snapshot.data![index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCentralLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.handyman, size: 45, color: Colors.black),
      ),
    );
  }

  // --- OVDJE JE PROMJENA: DODAN GESTURE DETECTOR ---
  Widget _buildOglasCard(Oglas oglas) {
    return GestureDetector(
      onTap: () {
        // AKTIVIRANO: Sada šaljemo oglas na DetaljiOglasa ekran
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetaljiOglasa(oglas: oglas)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.green[200],
                child: const Icon(Icons.image, color: Colors.white),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy.').format(oglas.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    oglas.naslov,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Autor: ${oglas.autorIme}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Isplata: ${oglas.isplata}€',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.error_outline, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 70,
      color: footerColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/ekrani/job_hub'),
            child: const Icon(Icons.handyman, size: 35, color: Colors.black),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF6D3F3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
          const Icon(Icons.chat_bubble_outline, size: 35, color: Colors.black),
        ],
      ),
    );
  }
}
