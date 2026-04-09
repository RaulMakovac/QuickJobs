import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quickjobs/ekrani/oglas.dart'; // Provjeri je li ovo točan put do DetaljiOglasa
import 'korisnicki_profil.dart';

// --- MODELI (Ostavljeni ovdje radi sigurnosti) ---
class Oglas {
  final String id;
  final String naslov;
  final String opis;
  final String isplata;
  final String adresa;
  final String status;
  final String? autorIme;
  final String? autorId;
  final String? obavljacId;
  final DateTime createdAt;

  Oglas({
    required this.id,
    required this.naslov,
    required this.opis,
    required this.isplata,
    required this.adresa,
    required this.status,
    this.autorIme,
    this.autorId,
    this.obavljacId,
    required this.createdAt,
  });

  factory Oglas.fromJson(Map<String, dynamic> json) {
    final profileData = json['autor'] as Map<String, dynamic>?;
    return Oglas(
      id: json['id'] ?? '',
      naslov: json['naslov_oglasa'] ?? 'Bez naslova',
      opis: json['opis_oglasa'] ?? '',
      isplata: json['isplata_oglasa']?.toString() ?? '0',
      adresa: json['adresa_oglasa'] ?? '',
      status: json['status_oglasa'] ?? 'otvoren',
      obavljacId: json['obavljac_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      autorId: profileData != null ? profileData['id'] : json['autor_id'],
      autorIme: profileData != null ? profileData['puno_ime'] : 'Nepoznat autor',
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
  
  // Kontroleri i varijable filtera
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _lokacijaController = TextEditingController();
  String _searchQuery = "";
  double _minIsplata = 0;
  bool _prikaziFiltere = false;

  // Boje
  static const bgColor = Color(0xFFE5D9D6);
  static const cardColor = Color(0xFF8F6E68);
  static const searchBarColor = Color(0xFFD1BDB9);
  static const darkBrown = Color(0xFF4A2C29);
  static const footerColor = Color(0xFF8F6E68);

  // Funkcija za dohvaćanje podataka iz Supabase-a
  Future<List<Oglas>> dohvatiOglase() async {
    try {
      final user = supabase.auth.currentUser;

      var query = supabase
          .from('oglasi')
          .select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime)')
          .eq('status_oglasa', 'otvoren')
          .filter('obavljac_id', 'is', null);

      // Primjena pretrage po naslovu
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('naslov_oglasa', '%$_searchQuery%');
      }

      // Primjena filtera isplate
      if (_minIsplata > 0) {
        query = query.gte('isplata_oglasa', _minIsplata);
      }

      // Makni vlastite oglase
      if (user != null) {
        query = query.neq('autor_id', user.id);
      }

      final response = await query.order('created_at', ascending: false);
      final List data = response as List;
      return data.map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Greška pri dohvaćanju: $e");
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
                  const Icon(Icons.settings, size: 35, color: darkBrown),
                  _buildCentralLogo(),
                  IconButton(
                    icon: const Icon(Icons.account_box, size: 35, color: darkBrown),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KorisnickiProfil())),
                  ),
                ],
              ),
            ),

            // --- SEARCH BAR I FILTER PANEL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: searchBarColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.black54),
                        hintText: 'Pretraži poslove...',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _prikaziFiltere ? Icons.expand_less : Icons.tune,
                            color: darkBrown,
                          ),
                          onPressed: () => setState(() => _prikaziFiltere = !_prikaziFiltere),
                        ),
                      ),
                    ),
                  ),

                  // EKRAN DODATNIH FILTERA
                  if (_prikaziFiltere)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: searchBarColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Min. isplata", style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
                              Text("${_minIsplata.toInt()}€", style: const TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
                            ],
                          ),
                          Slider(
                            value: _minIsplata,
                            min: 0,
                            max: 200,
                            divisions: 20,
                            activeColor: darkBrown,
                            inactiveColor: Colors.white24,
                            onChanged: (value) => setState(() => _minIsplata = value),
                          ),
                          const SizedBox(height: 10),
                          const Text("Lokacija", style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _lokacijaController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: "Svi gradovi (uskoro)",
                              prefixIcon: const Icon(Icons.location_on, color: darkBrown),
                              filled: true,
                              fillColor: Colors.white24,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- LISTA OGLASA ---
            Expanded(
              child: FutureBuilder<List<Oglas>>(
                future: dohvatiOglase(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: darkBrown));
                  }
                  final oglasi = snapshot.data ?? [];
                  if (oglasi.isEmpty) {
                    return const Center(child: Text("Nema dostupnih oglasa."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: oglasi.length,
                    itemBuilder: (context, index) => _buildOglasCard(oglasi[index]),
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

  // --- POMOĆNI WIDGETI ---

  Widget _buildCentralLogo() {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
      child: const Center(child: Icon(Icons.handyman, size: 45, color: Colors.black)),
    );
  }

  Widget _buildOglasCard(Oglas oglas) {
    return GestureDetector(
      onTap: () {
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
                width: 80, height: 80,
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
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
