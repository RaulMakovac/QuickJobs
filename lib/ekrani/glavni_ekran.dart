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

  Oglas copyWith({String? autorIme}) { 
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
    // Dohvaćamo definirane boje i provjeravamo aktivni mod teme
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
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
                          boje,
                        ),
                        _buildCentralLogo(isDark),
                        _buildHeaderIcon(
                          Icons.account_box,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KorisnickiProfil(),
                            ),
                          ),
                          boje,
                          size: 35,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. SEARCH BAR & FILTERS
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchDelegate(
                  visina: _prikaziFiltere ? 265 : 80,
                  bgColor: boje.bg!.withValues(alpha: 0.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _prikaziFiltere
                          ? boje.C?.withValues(alpha: 0.95)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                    ),
                    padding: const EdgeInsets.only(
                      left: 25,
                      right: 25,
                      top: 10,
                    ),
                    child: Column(
                      children: [_buildSearchBar(boje), _buildFilterPanel(boje)],
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
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(50),
                            child: CircularProgressIndicator(color: boje.A),
                          ),
                        ),
                      );
                    }
                    final oglasi = snapshot.data ?? [];
                    if (oglasi.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(50),
                            child: Text(
                              "Nema dostupnih oglasa.",
                              style: TextStyle(color: boje.A),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildOglasCard(oglasi[index], boje),
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
      bottomNavigationBar: _buildBottomNav(boje),
    );
  }

  Widget _buildHeaderIcon(
    IconData icon,
    VoidCallback onTap,
    QuickJobsColors boje, {
    double size = 28,
  }) {
    return IconButton(
      icon: Icon(icon, color: boje.A, size: size),
      onPressed: onTap,
    );
  }

  Widget _buildCentralLogo(bool isDark) {
    return SvgPicture.asset(
      isDark 
          ? 'assets/images/logo_darkmode.svg' 
          : 'assets/images/logo_lightmode.svg',
      width: 75,
      height: 75,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSearchBar(QuickJobsColors boje) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: boje.B,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: boje.A),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: boje.A?.withValues(alpha: 0.7)),
          hintText: 'Pretraži poslove...',
          hintStyle: TextStyle(color: boje.A?.withValues(alpha: 1.0)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _prikaziFiltere ? Icons.expand_less : Icons.tune,
              color: boje.A,
            ),
            onPressed: () => setState(() => _prikaziFiltere = !_prikaziFiltere),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(QuickJobsColors boje) {
    List<String> stavkeKategorija = [
      "Sve kategorije",
      ...kategorijeSaIkonama.keys,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _prikaziFiltere ? 170 : 0,
      margin: EdgeInsets.only(top: _prikaziFiltere ? 10 : 0),
      padding: EdgeInsets.all(_prikaziFiltere ? 15 : 0),
      clipBehavior: Clip.none,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _prikaziFiltere ? 1.0 : 0.0,
        child: OverflowBox(
          maxHeight: 170,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Min. isplata",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                    ),
                  ),
                  Text(
                    "${_minIsplata.toInt()}€",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _minIsplata,
                min: 0,
                max: 200,
                divisions: 20,
                activeColor: boje.A,
                inactiveColor: boje.B?.withValues(alpha: 0.3),
                onChanged: (value) => setState(() => _minIsplata = value),
              ),
              const SizedBox(height: 5),
              Text(
                "Kategorija posla",
                style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _odabranaKategorija ?? "Sve kategorije",
                dropdownColor: boje.C,
                style: TextStyle(
                  color: boje.A,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: boje.bg?.withValues(alpha: 0.4),
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
                          color: boje.A,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(kategorija, style: TextStyle(color: boje.A)),
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

  Widget _buildOglasCard(Oglas oglas, QuickJobsColors boje) {
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
          color: boje.C,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 70,
                height: 70,
                color: boje.bg?.withValues(alpha: 0.3),
                child: Icon(ikonaKategorije, color: boje.A, size: 35),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy.').format(oglas.createdAt),
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
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
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Autor: ${oglas.autorIme}',
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${oglas.isplata}€',
                      style: TextStyle(
                        color: boje.A,
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

  Widget _buildBottomNav(QuickJobsColors boje) {
    return Container(
      height: 70,
      color: boje.B,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(Icons.handyman, size: 30, color: boje.A),
            onPressed: () async {
              await Navigator.pushNamed(context, '/ekrani/job_hub');
              setState(() {});
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: boje.A,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: boje.bg, size: 25),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              size: 30,
              color: boje.A,
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
  final Color bgColor;

  _StickySearchDelegate({
    required this.child,
    required this.visina,
    required this.bgColor,
  });

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
      color: bgColor, 
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
    return oldDelegate.visina != visina || oldDelegate.bgColor != bgColor;
  }
}