import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../dekor.dart';
import '../services/oglas_service.dart';

class AzurirajOglas extends StatefulWidget {
  final Oglas oglas;
  const AzurirajOglas({super.key, required this.oglas});

  @override
  State<AzurirajOglas> createState() => _AzurirajOglasState();
}

class _AzurirajOglasState extends State<AzurirajOglas> {
  final OglasService _oglasService = OglasService();

  late TextEditingController _naslovController;
  late TextEditingController _opisController;
  late TextEditingController _isplataController;
  late TextEditingController _adresaController;

  double? _odabraniLat;
  double? _odabraniLng;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _naslovController = TextEditingController(text: widget.oglas.naslov);
    _opisController = TextEditingController(text: widget.oglas.opis);
    _isplataController = TextEditingController(text: widget.oglas.isplata);
    _adresaController = TextEditingController(text: widget.oglas.adresa);
    _odabraniLat = widget.oglas.lat;
    _odabraniLng = widget.oglas.lng;
  }

  @override
  void dispose() {
    _naslovController.dispose();
    _opisController.dispose();
    _isplataController.dispose();
    _adresaController.dispose();
    super.dispose();
  }

  Future<void> _odaberiLokacijuNaMapi(QuickJobsColors boje) async {
    LatLng pocetnaTocka = const LatLng(45.3271, 14.4422);

    if (_odabraniLat != null && _odabraniLng != null) {
      pocetnaTocka = LatLng(_odabraniLat!, _odabraniLng!);
    } else if (_adresaController.text.trim().isNotEmpty) {
      try {
        final lokacije = await locationFromAddress(_adresaController.text.trim());
        if (lokacije.isNotEmpty) {
          pocetnaTocka = LatLng(lokacije.first.latitude, lokacije.first.longitude);
        }
      } catch (_) {}
    }

    LatLng privremenaTocka = pocetnaTocka;
    String privremenaAdresa = _adresaController.text.trim();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: boje.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(modalContext).size.height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.map_rounded, color: boje.A),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Odaberi lokaciju na karti",
                            style: TextStyle(
                              color: boje.A,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: Icon(Icons.close, color: boje.A),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      privremenaAdresa.isNotEmpty
                          ? privremenaAdresa
                          : "Tapni na kartu za postavljanje pina",
                      style: TextStyle(
                        color: boje.A?.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: privremenaTocka,
                            initialZoom: 15.0,
                            onTap: (tapPosition, point) async {
                              setModalState(() {
                                privremenaTocka = point;
                              });
                              try {
                                final placemarks = await placemarkFromCoordinates(
                                  point.latitude,
                                  point.longitude,
                                );
                                if (placemarks.isNotEmpty) {
                                  final p = placemarks.first;
                                  final dijelovi = [
                                    p.street,
                                    p.locality,
                                  ].where((e) => e != null && e.trim().isNotEmpty).toList();
                                  if (dijelovi.isNotEmpty) {
                                    setModalState(() {
                                      privremenaAdresa = dijelovi.join(', ');
                                    });
                                  }
                                }
                              } catch (_) {}
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.quickjobs.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: privremenaTocka,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.redAccent,
                                    size: 44,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: boje.A,
                          foregroundColor: boje.bg,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _odabraniLat = privremenaTocka.latitude;
                            _odabraniLng = privremenaTocka.longitude;
                            if (privremenaAdresa.isNotEmpty) {
                              _adresaController.text = privremenaAdresa;
                            }
                          });
                          Navigator.pop(modalContext);
                        },
                        child: const Text(
                          "Potvrdi lokaciju",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateOglas() async {
    if (_isLoading) return;

    if (_naslovController.text.trim().isEmpty ||
        _adresaController.text.trim().isEmpty ||
        _isplataController.text.trim().isEmpty ||
        _opisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Molimo ispunite sva polja prije spremanja."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _oglasService.azurirajOglas(
        oglasId: widget.oglas.id,
        naslov: _naslovController.text,
        opis: _opisController.text,
        isplata: _isplataController.text,
        adresa: _adresaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oglas uspješno ažuriran!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, boje, widget.oglas.naslov),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 36),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: boje.C,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              "Naslov posla",
                              _naslovController,
                              Icons.work_outline,
                              boje,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              "Lokacija / Adresa",
                              _adresaController,
                              Icons.location_on_outlined,
                              boje,
                              suffixIcon: IconButton(
                                icon: Icon(Icons.map_rounded, color: boje.A),
                                tooltip: "Odaberi na karti",
                                onPressed: () => _odaberiLokacijuNaMapi(boje),
                              ),
                            ),
                            if (_odabraniLat != null && _odabraniLng != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "Koordinate: ${_odabraniLat!.toStringAsFixed(4)}, ${_odabraniLng!.toStringAsFixed(4)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: boje.A?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            _buildInputField(
                              "Isplata (€)",
                              _isplataController,
                              Icons.euro_symbol_rounded,
                              boje,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 18),
                            _buildInputField(
                              "Detaljan opis",
                              _opisController,
                              Icons.notes_rounded,
                              boje,
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _isLoading ? null : _updateOglas,
                        child: Column(
                          children: [
                            Container(
                              height: 64,
                              width: 64,
                              decoration: BoxDecoration(
                                color: boje.A,
                                shape: BoxShape.circle,
                              ),
                              child: _isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(18.0),
                                      child: CircularProgressIndicator(
                                        color: boje.bg,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check_rounded,
                                      size: 34,
                                      color: boje.bg,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLoading ? "Spremanje..." : "Spremi promjene",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: boje.A,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    QuickJobsColors boje,
    String naslovPosla,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: boje.A),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Uredi oglas",
                  style: TextStyle(
                    fontSize: 14,
                    color: boje.A?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '"$naslovPosla"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: boje.A,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String labela,
    TextEditingController controller,
    IconData icon,
    QuickJobsColors boje, {
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            labela,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: boje.A?.withValues(alpha: 0.8),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 16, color: boje.A),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
              child: Icon(icon, color: boje.A, size: 22),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: boje.bg?.withValues(alpha: 0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}