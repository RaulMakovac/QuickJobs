import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:quickjobs/ekrani/oglas.dart';
import 'korisnicki_profil.dart';
import '../dekor.dart';
import 'postavke.dart';
import '../banProvjera.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- MODEL Oglas ---
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
  final bool jeReportan;
  final String kategorija;

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
    this.jeReportan = false,
    this.kategorija = "Ostalo",
  });

  Oglas copyWith({String? autorIme}) { // potrebno za ažuriranje imena autora nakon učitavanja oglasa, jer se ime nalazi u povezanom profilu
    return Oglas(
      id: id,
      naslov: naslov,
      opis: opis,
      isplata: isplata,
      adresa: adresa,
      status: status,
      autorId: autorId,
      obavljacId: obavljacId,
      createdAt: createdAt,
      autorIme: autorIme ?? this.autorIme,
      jeReportan: jeReportan,
      kategorija: kategorija,
    );
  }

  factory Oglas.fromJson(Map<String, dynamic> json) {
    final profileData = json['autor'] as Map<String, dynamic>?;
    final reportsList = json['reports'] as List?;
    bool reportan = reportsList != null && reportsList.isNotEmpty;

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
      autorId: profileData?['id'] ?? json['autor_id']?.toString(),
      autorIme: profileData?['puno_ime'] ?? 'Autor oglasa',
      jeReportan: reportan,
      kategorija: json['kategorija'] ?? 'Ostalo',
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

  String _searchQuery = "";
  double _minIsplata = 0;
  String? _odabranaKategorija;
  bool _prikaziFiltere = false;

  static const bgColor = Color(0xFFE5D9D6);
  static const cardColor = Color(0xFF8F6E68);
  static const searchBarColor = Color(0xFFD1BDB9);
  static const darkBrown = Color(0xFF4A2C29);

  Future<List<Oglas>> dohvatiOglase() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final prijaveResponse = await supabase
          .from('prijave')
          .select('oglas_id')
          .eq('korisnik_id', user.id);
      final prijavljeniOglasiIds = (prijaveResponse as List)
          .map((item) => item['oglas_id'].toString())
          .toList();

      var query = supabase
          .from('oglasi')
          .select(
            '*, autor:profiles!oglasi_autor_id_fkey(puno_ime), reports(id)',
          )
          .eq('status_oglasa', 'otvoren')
          .filter('obavljac_id', 'is', null);

      if (prijavljeniOglasiIds.isNotEmpty) {
        query = query.not('id', 'in', '(${prijavljeniOglasiIds.join(',')})');
      }

      query = query.neq('autor_id', user.id);

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('naslov_oglasa', '%$_searchQuery%');
      }

      if (_minIsplata > 0) {
        query = query.gte('isplata_oglasa', _minIsplata);
      }

      if (_odabranaKategorija != null &&
          _odabranaKategorija != "Sve kategorije") {
        query = query.eq('kategorija', _odabranaKategorija!);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

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
    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                expandedHeight: 120,
                floating: false,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderIcon(
                          Icons.settings_outlined,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PostavkeEkran(
                                dolaziIzJednostavnog: false,
                              ),
                            ),
                          ),
                        ),
                        _buildCentralLogo(),
                        _buildHeaderIcon(
                          Icons.account_box,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KorisnickiProfil(),
                            ),
                          ),
                          size: 35,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. SEARCH BAR & FILTERS - Spojeni panel koji se rasteže
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  visina: _prikaziFiltere
                      ? 265
                      : 80,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _prikaziFiltere
                          ? searchBarColor.withOpacity(0.95)
                          : const Color.fromARGB(0, 0, 0, 0),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      left: 25,
                      right: 25,
                      top: 10,
                    ),
                    child: Column(
                      children: [_buildSearchBar(), _buildFilterPanel()],
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
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: CircularProgressIndicator(color: darkBrown),
                          ),
                        ),
                      );
                    }
                    final oglasi = snapshot.data ?? [];
                    if (oglasi.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child: Text("Nema dostupnih oglasa."),
                          ),
                        ),
                      );
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

  Widget _buildHeaderIcon(
    IconData icon,
    VoidCallback onTap, {
    double size = 28,
  }) {
    return IconButton(
      icon: Icon(icon, color: darkBrown, size: size),
      onPressed: onTap,
    );
  }

  Widget _buildCentralLogo() {
    return SvgPicture.asset(
      'assets/images/QJ_Logo.svg',
      width: 75,
      height: 75,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
    );
  }

  // FIKSIRANO: Korištenjem OverflowBox-a i AnimatedOpacity-a, panel se može vizualno proširiti i sakriti bez da stvarno mijenja svoju veličinu u layoutu, što sprječava overflow greške
  Widget _buildFilterPanel() {
    List<String> stavkeKategorija = [
      "Sve kategorije",
      ...kategorijeSaIkonama.keys,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _prikaziFiltere ? 170 : 0,
      margin: EdgeInsets.only(top: _prikaziFiltere ? 10 : 0),
      // Kada se zatvara, padding mora biti 0, inače on sam stvara overflow
      padding: EdgeInsets.all(_prikaziFiltere ? 15 : 0),
      decoration: const BoxDecoration(),
      clipBehavior: Clip.none,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _prikaziFiltere ? 1.0 : 0.0,
        // OverflowBox dopušta elementima da zadrže svoju veličinu dok se kontejner skuplja u nulu
        child: OverflowBox(
          maxHeight: 170, //PROMJENIIIII
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Min. isplata",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: darkBrown,
                    ),
                  ),
                  Text(
                    "${_minIsplata.toInt()}€",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
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
              const SizedBox(height: 5),
              const Text(
                "Kategorija posla",
                style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _odabranaKategorija ?? "Sve kategorije",
                dropdownColor: searchBarColor,
                style: const TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white30,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: stavkeKategorija.map((String kategorija) {
                  return DropdownMenuItem<String>(
                    value: kategorija,
                    child: Row(
                      children: [
                        Icon(
                          kategorijeSaIkonama[kategorija] ??
                              Icons.layers_rounded,
                          color: darkBrown,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(kategorija),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (novoStanje) {
                  setState(() {
                    _odabranaKategorija = novoStanje;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOglasCard(Oglas oglas) {
    final ikonaKategorije =
        kategorijeSaIkonama[oglas.kategorija] ?? Icons.more_horiz_rounded;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetaljiOglasa(oglas: oglas)),
        );
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 70,
                height: 70,
                color: const Color(0xFFE5D9D6).withOpacity(0.25),
                child: Icon(ikonaKategorije, color: Colors.white, size: 35),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy.').format(oglas.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  if (oglas.jeReportan)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 250, 122, 122),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Rizičan oglas",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    oglas.naslov,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Autor: ${oglas.autorIme}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${oglas.isplata}€',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
      color: const Color(0xFF83645E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.handyman, size: 30, color: Colors.black),
            onPressed: () async {
              await Navigator.pushNamed(context, '/ekrani/job_hub');
              setState(() {});
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF6D3F3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 25),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 30,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pushNamed(context, '/ekrani/chat_hub'),
          ),
        ],
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double visina;

  _StickySearchDelegate({required this.child, required this.visina});

  @override
  double get minExtent => visina;
  @override
  double get maxExtent => visina;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFE5D9D6), 
      child: ClipRect(
        child: OverflowBox(
          minHeight: 0,
          maxHeight: visina,
          alignment: Alignment.topCenter,
          child: SizedBox(height: visina, child: child),
        ),
      ),
    );
  }

  
  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) {
    return true; 
  }
}


