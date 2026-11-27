import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickjobs/ekrani/oglas.dart';
import '/services/oglas_service.dart';
import 'korisnicki_profil.dart';
import '../dekor.dart';
import 'postavke.dart';
import '../banProvjera.dart';

class glavni_ekran extends StatefulWidget {
  const glavni_ekran({super.key});

  @override
  State<glavni_ekran> createState() => _glavni_ekranState();
}

class _glavni_ekranState extends State<glavni_ekran> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final OglasService _oglasService = OglasService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  double _minIsplata = 0;
  String? _odabranaKategorija;
  bool _prikaziFiltere = false;

  // Filter udaljenosti (null = isključeno)
  double? _maxUdaljenostKm;
  // Stvarna lokacija korisnika (popunjava se preko Geolocator paketa)
  double? _korisnikLat;
  double? _korisnikLng;

  late Future<List<Oglas>> _oglasiFuture;

  @override
  void initState() {
    super.initState();
    _oglasiFuture = _dohvatiOglase();
    _dohvatiLokacijuKorisnika();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final banPoruka = await AuthProvjera.ProvjeriBanKorisnika();
      if (banPoruka != null && mounted) {
        AuthProvjera.prikaziBanDialog(context, banPoruka);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _dohvatiLokacijuKorisnika() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('GPS serviceEnabled: $serviceEnabled');
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('GPS permission prije: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('GPS permission nakon zahtjeva: $permission');
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      debugPrint('GPS pozicija: ${position.latitude}, ${position.longitude}');

      if (!mounted) return;
      setState(() {
        _korisnikLat = position.latitude;
        _korisnikLng = position.longitude;
        _oglasiFuture = _dohvatiOglase();
      });
    } catch (e) {
      debugPrint("Greška pri dohvatu GPS lokacije: $e");
    }
  }

  void _osvjeziOglase() {
    setState(() {
      _oglasiFuture = _dohvatiOglase();
    });
  }

  Future<List<Oglas>> _dohvatiOglase() {
    final String? efektivnaKategorija =
        (_odabranaKategorija == null || _odabranaKategorija == "Sve kategorije")
        ? null
        : _odabranaKategorija;

    if (_maxUdaljenostKm != null &&
        _korisnikLat != null &&
        _korisnikLng != null) {
      return _oglasService.dohvatiOglaseUNutarRadijusa(
        lat: _korisnikLat!,
        lng: _korisnikLng!,
        radijusKm: _maxUdaljenostKm!,
        searchQuery: _searchQuery,
        minIsplata: _minIsplata,
        odabranaKategorija: efektivnaKategorija,
      );
    }

    return _oglasService.dohvatiDostupneOglase(
      searchQuery: _searchQuery,
      minIsplata: _minIsplata,
      odabranaKategorija: efektivnaKategorija,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double sirinaEkrana = MediaQuery.sizeOf(context).width;
    final bool jeWebLayout = sirinaEkrana >= 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: boje.bg,
      drawer: jeWebLayout ? _buildWebDrawer(boje, isDark) : null,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWebLayout
              ? _buildWebContent(boje, isDark, sirinaEkrana)
              : _buildMobileContent(boje, isDark),
        ),
      ),
      bottomNavigationBar: jeWebLayout ? null : _buildBottomNav(boje),
    );
  }

  // WEB LAYOUT: Top bar (Logo + Pretraga + Objavi + Hamburger) + brze kategorije + mreža oglasa
  Widget _buildWebContent(
    QuickJobsColors boje,
    bool isDark,
    double sirinaEkrana,
  ) {
    final double bocniPadding = sirinaEkrana > 1360 ? 72 : 36;

    return CustomScrollView(
      slivers: [
        // Gornja navigacijska traka
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.fromLTRB(bocniPadding, 16, bocniPadding, 16),
            decoration: BoxDecoration(
              color: (boje.C ?? boje.B)?.withValues(alpha: 1.0),
              border: Border(
                bottom: BorderSide(
                  color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                      _minIsplata = 0;
                      _maxUdaljenostKm = null;
                      _odabranaKategorija = null;
                    });
                    _osvjeziOglase();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCentralLogo(isDark, size: 46),
                      const SizedBox(width: 10),
                      Text(
                        'QuickJobs',
                        style: TextStyle(
                          color: boje.A,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: _buildSearchBar(boje),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/ekrani/objava_oglasa');
                    _osvjeziOglase();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: boje.A,
                    foregroundColor: boje.bg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Objavi oglas',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: boje.A, size: 30),
                  tooltip: 'Izbornik',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ],
            ),
          ),
        ),

        // Prošireni filter panel (ako je uključen na ikoni filtera)
        if (_prikaziFiltere)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(bocniPadding, 14, bocniPadding, 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (boje.C ?? boje.B)?.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
                      ),
                    ),
                    child: _buildFilterPanel(boje),
                  ),
                ),
              ),
            ),
          ),

        // Brzi čipovi kategorija ispod tražilice
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(bocniPadding, 18, bocniPadding, 6),
            child: _buildWebCategoryChips(boje),
          ),
        ),

        // Mreža oglasa
        SliverPadding(
          padding: EdgeInsets.fromLTRB(bocniPadding, 10, bocniPadding, 32),
          sliver: _buildOglasiSliver(boje, jeMreza: true),
        ),
      ],
    );
  }

  Widget _buildWebCategoryChips(QuickJobsColors boje) {
    final List<String> kategorije = [
      "Sve kategorije",
      ...kategorijeSaIkonama.keys,
    ];
    final String aktivna = _odabranaKategorija ?? "Sve kategorije";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kategorije.map((kat) {
          final bool odabrano = aktivna == kat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kat != "Sve kategorije") ...[
                    Icon(
                      kategorijeSaIkonama[kat] ?? Icons.layers_rounded,
                      size: 16,
                      color: odabrano ? boje.bg : boje.A,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    kat,
                    style: TextStyle(
                      color: odabrano ? boje.bg : boje.A,
                      fontWeight: odabrano ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              selected: odabrano,
              selectedColor: boje.A,
              backgroundColor: (boje.C ?? boje.B)?.withValues(alpha: 0.8),
              side: BorderSide(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (_) {
                setState(() {
                  _odabranaKategorija = kat == "Sve kategorije" ? null : kat;
                });
                _osvjeziOglase();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // POSTOJEĆI MOBILNI LAYOUT
  Widget _buildMobileContent(QuickJobsColors boje, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          expandedHeight: 120,
          floating: false,
          pinned: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderIcon(
                    Icons.settings_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PostavkeEkran(dolaziIzJednostavnog: false),
                      ),
                    ),
                    boje,
                  ),
                  _buildCentralLogo(isDark, size: 75),
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
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchDelegate(
            visina: _prikaziFiltere ? 335 : 80,
            bgColor: boje.bg!.withValues(alpha: 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: _prikaziFiltere
                    ? boje.C?.withValues(alpha: 0.95)
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(25)),
              ),
              padding: const EdgeInsets.only(left: 25, right: 25, top: 10),
              child: Column(
                children: [_buildSearchBar(boje), _buildFilterPanel(boje)],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          sliver: _buildOglasiSliver(boje, jeMreza: false),
        ),
      ],
    );
  }

  Widget _buildOglasiSliver(QuickJobsColors boje, {required bool jeMreza}) {
    return FutureBuilder<List<Oglas>>(
      future: _oglasiFuture,
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

        if (jeMreza) {
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              mainAxisExtent: 190,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildWebOglasCard(oglasi[index], boje),
              childCount: oglasi.length,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildOglasCard(oglasi[index], boje),
            childCount: oglasi.length,
          ),
        );
      },
    );
  }

  // WEB KARTICA OGLASA: jasniji raspored (kategorija + cijena gore, naslov/meta u sredini, datum + akcija dolje)
  Widget _buildWebOglasCard(Oglas oglas, QuickJobsColors boje) {
    final ikonaKategorije =
        kategorijeSaIkonama[oglas.kategorija] ?? Icons.more_horiz_rounded;

    double? izracunajUdaljenostKm() {
      if (oglas.udaljenostKm != null) return oglas.udaljenostKm;
      if (oglas.lat != null &&
          oglas.lng != null &&
          _korisnikLat != null &&
          _korisnikLng != null) {
        const distance = Distance();
        final km = distance.as(
          LengthUnit.Kilometer,
          LatLng(_korisnikLat!, _korisnikLng!),
          LatLng(oglas.lat!, oglas.lng!),
        );
        return double.parse(km.toStringAsFixed(1));
      }
      return null;
    }

    final udaljenost = izracunajUdaljenostKm();

    return _HoverCardWrapper(
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetaljiOglasa(oglas: oglas),
            ),
          );
          _osvjeziOglase();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: boje.C,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gornji red: ikona kategorije + bedž cijene
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: boje.bg?.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(ikonaKategorije, color: boje.A, size: 22),
                      ),
                      if (oglas.jeReportan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 250, 122, 122),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Rizičan oglas",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: boje.B,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${oglas.isplata}€',
                      style: TextStyle(
                        color: boje.A,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              // Sredina: naslov + autor i udaljenost
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    oglas.naslov,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    udaljenost != null
                        ? '${oglas.autorIme ?? 'Nepoznat autor'} · ${udaljenost.toStringAsFixed(1)} km'
                        : (oglas.autorIme ?? 'Nepoznat autor'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.78),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Dno kartice: datum i poziv na detalje
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd.MM.yyyy.').format(oglas.createdAt),
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Detalji →',
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebDrawer(QuickJobsColors boje, bool isDark) {
    return Drawer(
      backgroundColor: boje.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildCentralLogo(isDark, size: 48),
                  const SizedBox(width: 12),
                  Text(
                    'QuickJobs',
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.add_circle_outline_rounded, color: boje.A),
              title: Text(
                'Objavi oglas',
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/ekrani/objava_oglasa');
                _osvjeziOglase();
              },
            ),
            ListTile(
              leading: Icon(Icons.chat_bubble_outline_rounded, color: boje.A),
              title: Text(
                'Chat',
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ekrani/chat_hub');
              },
            ),
            ListTile(
              leading: Icon(Icons.handyman_outlined, color: boje.A),
              title: Text(
                'Moji poslovi',
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, '/ekrani/job_hub');
                _osvjeziOglase();
              },
            ),
            ListTile(
              leading: Icon(Icons.person_outline_rounded, color: boje.A),
              title: Text(
                'Korisnički profil',
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KorisnickiProfil(),
                  ),
                );
              },
            ),
            const Divider(height: 28),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: boje.A),
              title: Text(
                'Postavke',
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PostavkeEkran(dolaziIzJednostavnog: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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

  Widget _buildCentralLogo(bool isDark, {double size = 75}) {
    return SvgPicture.asset(
      isDark
          ? 'assets/images/logo_darkmode.svg'
          : 'assets/images/logo_lightmode.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

Widget _buildSearchBar(QuickJobsColors boje) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: boje.bg,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: (boje.A ?? Colors.black).withValues(
          alpha: isDark ? 0.25 : 0.28,
        ),
        width: 1.8,
      ),
    ),
    child: TextField(
      controller: _searchController,
      textAlignVertical: TextAlignVertical.center,
      onChanged: (value) {
        _searchQuery = value;
        _osvjeziOglase();
      },
      style: TextStyle(color: boje.A, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: Icon(
          Icons.search,
          color: boje.A?.withValues(alpha: 0.7),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        hintText: 'Pretraži poslove...',
        hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.75)),
        border: InputBorder.none,
        suffixIcon: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
    final List<String> stavkeKategorija = [
      "Sve kategorije",
      ...kategorijeSaIkonama.keys,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _prikaziFiltere ? 240 : 0,
      margin: EdgeInsets.only(top: _prikaziFiltere ? 10 : 0),
      padding: EdgeInsets.all(_prikaziFiltere ? 15 : 0),
      clipBehavior: Clip.none,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _prikaziFiltere ? 1.0 : 0.0,
        child: OverflowBox(
          maxHeight: 240,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Min. isplata + Reset
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
                  Row(
                    children: [
                      Text(
                        "${_minIsplata.toInt()}€",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: boje.A,
                        ),
                      ),
                      if (_minIsplata > 0) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _minIsplata = 0;
                            _osvjeziOglase();
                          },
                          child: Text(
                            "Reset",
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              color: boje.A?.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
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
                onChangeEnd: (value) {
                  _minIsplata = value;
                  _osvjeziOglase();
                },
              ),

              // Filter udaljenosti (km) + Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Maks. udaljenost",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _maxUdaljenostKm == null
                            ? "Sve"
                            : "${_maxUdaljenostKm!.toInt()} km",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: boje.A,
                        ),
                      ),
                      if (_maxUdaljenostKm != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _maxUdaljenostKm = null;
                            _osvjeziOglase();
                          },
                          child: Text(
                            "Reset",
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              color: boje.A?.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Slider(
                value: _maxUdaljenostKm ?? 0,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: boje.A,
                inactiveColor: boje.B?.withValues(alpha: 0.3),
                onChanged: (value) => setState(() {
                  _maxUdaljenostKm = value == 0 ? null : value;
                }),
                onChangeEnd: (value) {
                  _maxUdaljenostKm = value == 0 ? null : value;
                  _osvjeziOglase();
                },
              ),

              const SizedBox(height: 5),
              Text(
                "Kategorija posla",
                style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _odabranaKategorija ?? "Sve kategorije",
                dropdownColor: boje.C,
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
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
                  _odabranaKategorija = novoStanje;
                  _osvjeziOglase();
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

    double? izracunajUdaljenostKm() {
      if (oglas.udaljenostKm != null) return oglas.udaljenostKm;
      if (oglas.lat != null &&
          oglas.lng != null &&
          _korisnikLat != null &&
          _korisnikLng != null) {
        const distance = Distance();
        final km = distance.as(
          LengthUnit.Kilometer,
          LatLng(_korisnikLat!, _korisnikLng!),
          LatLng(oglas.lat!, oglas.lng!),
        );
        return double.parse(km.toStringAsFixed(1));
      }
      return null;
    }

    final udaljenost = izracunajUdaljenostKm();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetaljiOglasa(oglas: oglas)),
        );
        _osvjeziOglase();
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
                  if (udaljenost != null)
                    Text(
                      'Udaljenost: ${udaljenost.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: boje.A?.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
              _osvjeziOglase();
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: boje.A, shape: BoxShape.circle),
              child: Icon(Icons.add, color: boje.bg, size: 25),
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/ekrani/objava_oglasa'),
          ),
          IconButton(
            icon: Icon(Icons.chat, size: 30, color: boje.A),
            onPressed: () => Navigator.pushNamed(context, '/ekrani/chat_hub'),
          ),
        ],
      ),
    );
  }
}

class _HoverCardWrapper extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;

  const _HoverCardWrapper({required this.child, required this.borderRadius});

  @override
  State<_HoverCardWrapper> createState() => _HoverCardWrapperState();
}

class _HoverCardWrapperState extends State<_HoverCardWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.14 : 0.05),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 8 : 3),
            ),
          ],
        ),
        child: widget.child,
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
    return true;
  }
}
