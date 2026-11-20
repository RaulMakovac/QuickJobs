import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../services/oglas_service.dart';
import '../dekor.dart';

class ObjavaOglasa extends StatefulWidget {
  const ObjavaOglasa({super.key});

  @override
  State<ObjavaOglasa> createState() => _ObjavaOglasaState();
}

class _ObjavaOglasaState extends State<ObjavaOglasa> {
  final OglasService _oglasService = OglasService();

  final _naslovController = TextEditingController();
  final _adresaController = TextEditingController();
  final _isplataController = TextEditingController();
  final _opisController = TextEditingController();

  String _odabranaKategorija = "Ostalo";
  double? _odabraniLat;
  double? _odabraniLng;
  bool _isLoading = false;

  @override
  void dispose() {
    _naslovController.dispose();
    _adresaController.dispose();
    _isplataController.dispose();
    _opisController.dispose();
    super.dispose();
  }

  Future<void> _otvoriKartuZaLokaciju() async {
    final pocetna = (_odabraniLat != null && _odabraniLng != null)
        ? LatLng(_odabraniLat!, _odabraniLng!)
        : null;

    final rezultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OdabirLokacijeEkran(
          pocetnaLokacija: pocetna,
          pocetnaAdresa: _adresaController.text.trim(),
        ),
      ),
    );

    if (rezultat != null && mounted) {
      final LatLng? tocka = rezultat['point'] as LatLng?;
      final String? predlozenaAdresa = rezultat['adresa'] as String?;

      setState(() {
        if (tocka != null) {
          _odabraniLat = tocka.latitude;
          _odabraniLng = tocka.longitude;
        }
        // Ne prepisujemo ručno unesenu adresu ako već postoji tekst
        if (_adresaController.text.trim().isEmpty &&
            predlozenaAdresa != null &&
            predlozenaAdresa.trim().isNotEmpty) {
          _adresaController.text = predlozenaAdresa;
        }
      });
    }
  }

  Future<void> _objaviOglas() async {
    final naslov = _naslovController.text.trim();
    final adresa = _adresaController.text.trim();
    final isplata = _isplataController.text.trim();
    final opis = _opisController.text.trim();

    if (naslov.isEmpty || adresa.isEmpty || isplata.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Naziv, Adresa i Isplata su obavezni!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _oglasService.objaviOglas(
        naslov: naslov,
        adresa: adresa,
        isplata: isplata,
        opis: opis,
        kategorija: _odabranaKategorija,
        lat: _odabraniLat,
        lng: _odabraniLng,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oglas uspješno objavljen!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri objavi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      extendBody: true,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: boje.A,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Objavi posao',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: boje.A,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ovdje možete objaviti oglas za koji god posao vam je potrebna pomoć!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: boje.A?.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 30),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: boje.C,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: boje.A!.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          "Slika\nposla",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: boje.A, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _customField("Naziv posla", _naslovController, boje),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: _customField("Adresa:", _adresaController, boje),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: boje.C,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: boje.A!.withValues(alpha: 0.3), width: 1),
                      ),
                      child: IconButton(
                        onPressed: _otvoriKartuZaLokaciju,
                        icon: Icon(Icons.map_rounded, color: boje.A),
                        tooltip: 'Odaberi točnu lokaciju na karti',
                      ),
                    ),
                  ],
                ),
                if (_odabraniLat != null && _odabraniLng != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Odabrana točka: ${_odabraniLat!.toStringAsFixed(5)}, ${_odabraniLng!.toStringAsFixed(5)}',
                      style: TextStyle(
                        color: boje.A?.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 15),

                _customField("Isplata:", _isplataController, boje, isNumber: true),
                const SizedBox(height: 15),

                Container(
                  height: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: boje.C,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: boje.A!.withValues(alpha: 0.3), width: 1),
                  ),
                  child: TextField(
                    controller: _opisController,
                    maxLines: null,
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: "Opis posla...",
                      hintStyle: TextStyle(
                        color: boje.A?.withValues(alpha: 1.0),
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: boje.C,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: boje.A!.withValues(alpha: 0.3), width: 1),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _odabranaKategorija,
                    dropdownColor: boje.C,
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: boje.A,
                    ),
                    items: kategorijeSaIkonama.keys.map((String kategorija) {
                      return DropdownMenuItem<String>(
                        value: kategorija,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kategorijeSaIkonama[kategorija],
                              color: boje.A,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              kategorija,
                              style: TextStyle(
                                color: boje.A,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (novo) {
                      setState(() {
                        _odabranaKategorija = novo!;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 40),

                GestureDetector(
                  onTap: _isLoading ? null : _objaviOglas,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: boje.A,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: boje.bg,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            size: 50,
                            color: boje.bg,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customField(
    String hint,
    TextEditingController controller,
    QuickJobsColors boje, {
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: boje.B,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: boje.A!.withValues(alpha: 0.3), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(
          color: boje.A,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: boje.A?.withValues(alpha: 1.0),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _OdabirLokacijeEkran extends StatefulWidget {
  final LatLng? pocetnaLokacija;
  final String? pocetnaAdresa;

  const _OdabirLokacijeEkran({
    this.pocetnaLokacija,
    this.pocetnaAdresa,
  });

  @override
  State<_OdabirLokacijeEkran> createState() => _OdabirLokacijeEkranState();
}

class _OdabirLokacijeEkranState extends State<_OdabirLokacijeEkran> {
  final MapController _mapController = MapController();
  late LatLng _trenutnaTocka;
  String? _predlozenaAdresa;
  bool _trazimAdresu = false;

  static const LatLng _defaultCentar = LatLng(45.3271, 14.4422);

  @override
  void initState() {
    super.initState();
    _trenutnaTocka = widget.pocetnaLokacija ?? _defaultCentar;
    if (widget.pocetnaLokacija == null &&
        widget.pocetnaAdresa != null &&
        widget.pocetnaAdresa!.trim().isNotEmpty) {
      _pokusajPronaciAdresu(widget.pocetnaAdresa!.trim());
    }
  }

  Future<void> _pokusajPronaciAdresu(String adresa) async {
    try {
      final lokacije = await locationFromAddress(adresa);
      if (lokacije.isNotEmpty && mounted) {
        final nova = LatLng(lokacije.first.latitude, lokacije.first.longitude);
        setState(() => _trenutnaTocka = nova);
        _mapController.move(nova, 15);
      }
    } catch (_) {
      // Ako geocoding ne pronađe adresu, ostajemo na početnoj točki
    }
  }

  Future<void> _osvjeziAdresuZaTocku(LatLng tocka) async {
    setState(() => _trazimAdresu = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        tocka.latitude,
        tocka.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final dijelovi = [
          p.street,
          p.postalCode,
          p.locality,
        ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();

        if (dijelovi.isNotEmpty) {
          setState(() => _predlozenaAdresa = dijelovi.join(', '));
        }
      }
    } catch (_) {
      // Ne diramo postojeću adresu ako reverse geocoding ne uspije
    } finally {
      if (mounted) setState(() => _trazimAdresu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      appBar: AppBar(
        backgroundColor: boje.bg,
        foregroundColor: boje.A,
        title: const Text('Odaberi točnu lokaciju'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _trenutnaTocka,
                initialZoom: 14,
                onTap: (tapPosition, point) {
                  setState(() => _trenutnaTocka = point);
                  _osvjeziAdresuZaTocku(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.quickjobs',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _trenutnaTocka,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        size: 46,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: boje.C,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _trazimAdresu
                      ? 'Tražim adresu za odabranu točku...'
                      : (_predlozenaAdresa ??
                          'Dodirnite kartu za postavljanje točne točke.'),
                  style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lat: ${_trenutnaTocka.latitude.toStringAsFixed(5)}, '
                  'Lng: ${_trenutnaTocka.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    color: boje.A?.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: boje.A,
                    foregroundColor: boje.bg,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'point': _trenutnaTocka,
                      'adresa': _predlozenaAdresa,
                    });
                  },
                  child: const Text('Potvrdi lokaciju'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}