import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quickjobs/ekrani/oglas.dart';
import 'korisnicki_profil.dart';
import '../dekor.dart';
import 'postavke.dart';

// --- MODEL Oglas (Vraćen copyWith i factory) ---
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
    required this.id, required this.naslov, required this.opis,
    required this.isplata, required this.adresa, required this.status,
    this.autorIme, this.autorId, this.obavljacId, required this.createdAt,
  });

  Oglas copyWith({String? autorIme}) {
    return Oglas(
      id: id, naslov: naslov, opis: opis, isplata: isplata, adresa: adresa,
      status: status, autorId: autorId, obavljacId: obavljacId,
      createdAt: createdAt, autorIme: autorIme ?? this.autorIme,
    );
  }

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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      autorId: profileData?['id'] ?? json['autor_id']?.toString(),
      autorIme: profileData?['puno_ime'] ?? 'Nepoznat autor',
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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _lokacijaController = TextEditingController();
  String _searchQuery = "";
  double _minIsplata = 0;
  bool _prikaziFiltere = false;

  static const bgColor = Color(0xFFE5D9D6);
  static const cardColor = Color(0xFF8F6E68);
  static const searchBarColor = Color(0xFFD1BDB9);
  static const darkBrown = Color(0xFF4A2C29);

  Future<List<Oglas>> dohvatiOglase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];
      
      final prijaveResponse = await supabase.from('prijave').select('oglas_id').eq('korisnik_id', user.id);
      final prijavljeniOglasiIds = (prijaveResponse as List).map((item) => item['oglas_id'].toString()).toList();

      var query = supabase.from('oglasi').select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime)').eq('status_oglasa', 'otvoren').filter('obavljac_id', 'is', null);
      
      if (prijavljeniOglasiIds.isNotEmpty) {
        query = query.not('id', 'in', '(${prijavljeniOglasiIds.join(',')})');
      }
      
      query = query.neq('autor_id', user.id);
      if (_searchQuery.isNotEmpty) query = query.ilike('naslov_oglasa', '%$_searchQuery%');
      if (_minIsplata > 0) query = query.gte('isplata_oglasa', _minIsplata);

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 1. HEADER - Nestaje pri scrollu
              SliverAppBar(
                backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                expandedHeight: 120,
                floating: false,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderIcon(Icons.settings_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PostavkeEkran(dolaziIzJednostavnog: false)))),
                        _buildCentralLogo(),
                        _buildHeaderIcon(Icons.account_box, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KorisnickiProfil())), size: 35),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. SEARCH BAR - Lepi se na vrh, proziran da se vide krugovi
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  visina: _prikaziFiltere ? 255 : 80,
                  child: Container(
                    // Poluprozirna boja omogućuje krugovima da se vide
                    color: const Color.fromARGB(0, 0, 0, 0), 
                    padding: const EdgeInsets.only(left: 25, right: 25, top: 10, bottom: 5),
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        if (_prikaziFiltere) _buildFilterPanel(),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. LISTA OGLASA
              SliverPadding(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                sliver: FutureBuilder<List<Oglas>>(
                  future: dohvatiOglase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: darkBrown))));
                    }
                    final oglasi = snapshot.data ?? [];
                    if (oglasi.isEmpty) {
                      return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: Text("Nema dostupnih oglasa."))));
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildOglasCard(oglasi[index]),
                        ),
                        childCount: oglasi.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap, {double size = 28}) {
    return IconButton(icon: Icon(icon, color: darkBrown, size: size), onPressed: onTap);
  }

  Widget _buildCentralLogo() {
    return Container(
      width: 75, height: 75,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
      child: const Center(child: Icon(Icons.handyman, size: 40, color: Colors.black)),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: searchBarColor, borderRadius: BorderRadius.circular(25)),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.black54),
          hintText: 'Pretraži poslove...',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(_prikaziFiltere ? Icons.expand_less : Icons.tune, color: darkBrown),
            onPressed: () => setState(() => _prikaziFiltere = !_prikaziFiltere),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: searchBarColor.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
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
            value: _minIsplata, min: 0, max: 200, divisions: 20,
            activeColor: darkBrown, inactiveColor: Colors.white24,
            onChanged: (value) => setState(() => _minIsplata = value),
          ),
          const Text("Lokacija", style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
          const SizedBox(height: 5),
          TextField(
            controller: _lokacijaController, readOnly: true,
            decoration: InputDecoration(
              hintText: "Svi gradovi (uskoro)", prefixIcon: const Icon(Icons.location_on, color: darkBrown),
              filled: true, fillColor: Colors.white24,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOglasCard(Oglas oglas) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => DetaljiOglasa(oglas: oglas)));
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(width: 70, height: 70, color: Colors.green[200], child: const Icon(Icons.image, color: Colors.white)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd.MM.yyyy.').format(oglas.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(oglas.naslov, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Autor: ${oglas.autorIme}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Align(alignment: Alignment.bottomRight, child: Text('${oglas.isplata}€', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
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
      height: 70, color: const Color(0xFF83645E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.handyman, size: 30, color: Colors.black), onPressed: () async { await Navigator.pushNamed(context, '/ekrani/job_hub'); setState(() {}); }),
          IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF6D3F3A), shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.white, size: 25)), onPressed: () => Navigator.pushNamed(context, '/ekrani/objava_oglasa')),
          IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 30, color: Colors.black), onPressed: () => Navigator.pushNamed(context, '/ekrani/chat_hub')),
        ],
      ),
    );
  }
}

// --- DELEGAT ZA SEARCH BAR ---
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double visina;
  _StickySearchDelegate({required this.child, required this.visina});

  @override double get minExtent => visina;
  @override double get maxExtent => visina;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override bool shouldRebuild(_StickySearchDelegate oldDelegate) {
    return oldDelegate.visina != visina || oldDelegate.child != child;
  }
}
