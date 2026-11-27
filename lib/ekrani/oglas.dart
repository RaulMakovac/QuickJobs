import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../services/oglas_service.dart';
import '../services/prijava_service.dart';
import '../services/report_service.dart';
import '../dekor.dart';
import 'korisnicki_profil.dart';

class DetaljiOglasa extends StatelessWidget {
  final Oglas oglas;
  final bool samoPregled;

  DetaljiOglasa({super.key, required this.oglas, this.samoPregled = false});

  final PrijavaService _prijavaService = PrijavaService();
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool imaLokaciju =
        (oglas.lat != null && oglas.lng != null) ||
        oglas.adresa.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 200),
            child: Column(
              children: [
                _buildAppBar(context, boje),
                const SizedBox(height: 35),
                _buildJobTitleHeader(boje),

                const SizedBox(height: 15),
                _buildKategorijaBadge(boje),

                // UPOZORENJE ZAJEDNICE (REPORTS)
                if (oglas.jeReportan) ...[
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: boje.B?.withValues(alpha: 0.9),
                      border: Border.all(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (boje.A ?? Colors.black).withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.gavel_rounded, color: boje.A, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Upozorenje zajednice",
                                style: TextStyle(
                                  color: boje.A,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ovaj oglas je reportan od strane zajednice zbog sumnje na kršenje pravila ili prijevaru. Postupajte s oprezom!",
                                style: TextStyle(
                                  color: boje.A?.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 25),
                _buildAuthorSection(context, boje),

                const SizedBox(height: 25),
                _buildDetailRow(
                  'Adresa: ${oglas.adresa}',
                  Icons.location_on_rounded,
                  boje,
                  trailingIcon: imaLokaciju ? Icons.map_rounded : null,
                  onTap: imaLokaciju
                      ? () => _otvoriKartuOglasa(context, boje)
                      : null,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Isplata: ${oglas.isplata}€',
                  Icons.euro_rounded,
                  boje,
                ),

                const SizedBox(height: 25),
                _buildDescriptionCard(boje),

                const SizedBox(height: 45),

                if (samoPregled)
                  Column(
                    children: [
                      Icon(Icons.info_outline, color: boje.A, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'Pregled aktivne prijave',
                        style: TextStyle(
                          color: boje.A,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                else
                  _buildApplyButton(context, boje),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _otvoriKartuOglasa(
    BuildContext context,
    QuickJobsColors boje,
  ) async {
    LatLng? tocka;

    if (oglas.lat != null && oglas.lng != null) {
      tocka = LatLng(oglas.lat!, oglas.lng!);
    } else if (oglas.adresa.trim().isNotEmpty) {
      try {
        final lokacije = await locationFromAddress(oglas.adresa.trim());
        if (lokacije.isNotEmpty) {
          tocka = LatLng(lokacije.first.latitude, lokacije.first.longitude);
        }
      } catch (e) {
        debugPrint("Greška pri geokodiranju adrese: $e");
      }
    }

    if (!context.mounted) return;

    if (tocka == null) {
      _showSnack(
        context,
        "Nije moguće prikazati lokaciju na karti za ovu adresu.",
        isError: true,
      );
      return;
    }

    final LatLng prikazanaTocka = tocka;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: boje.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) {
        return SizedBox(
          height: MediaQuery.of(modalContext).size.height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: boje.A),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        oglas.adresa.isNotEmpty
                            ? oglas.adresa
                            : 'Lokacija posla',
                        style: TextStyle(
                          color: boje.A,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(modalContext),
                      icon: Icon(Icons.close, color: boje.A),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: prikazanaTocka,
                        initialZoom: 15.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.quickjobs.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: prikazanaTocka, // tvoja LatLng koordinata
                              width: 48,
                              height: 48,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.location_pin,
                                size: 48,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKategorijaBadge(QuickJobsColors boje) {
    final nazivKategorije = oglas.kategorija;
    final ikonaKategorije =
        kategorijeSaIkonama[nazivKategorije] ?? Icons.more_horiz_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: boje.B!.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikonaKategorije, color: boje.A, size: 20),
          const SizedBox(width: 8),
          Text(
            nazivKategorije,
            style: TextStyle(
              color: boje.A,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorSection(BuildContext context, QuickJobsColors boje) {
    return GestureDetector(
      onTap: () {
        if (oglas.autorId != null && oglas.autorId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  KorisnickiProfil(prikazaniKorisnikId: oglas.autorId),
            ),
          );
        } else {
          _showSnack(context, "Profil autora nije dostupan.", isError: true);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: boje.C,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: boje.B!.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            _buildSquareImage(boje),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, size: 30, color: boje.A),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          oglas.autorIme ?? 'Nepoznat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: boje.A,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 38),
                    child: Text(
                      'UVID U PROFIL POSLODAVCA',
                      style: TextStyle(
                        color: boje.A?.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: boje.A, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, QuickJobsColors boje) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handlePrijava(context),
          child: Container(
            width: 90,
            height: 90,
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
            child: Icon(Icons.check, size: 55, color: boje.bg),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Prijavi se na posao!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: boje.A,
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrijava(BuildContext context) async {
    try {
      await _prijavaService.prijavaNaOglas(oglas.id);

      if (context.mounted) {
        _showSnack(context, 'Uspješno prijavljeni!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(
          context,
          'Već ste prijavljeni ili je došlo do greške.',
          isError: true,
        );
      }
    }
  }

  Widget _buildAppBar(BuildContext context, QuickJobsColors boje) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, size: 30, color: boje.A),
        ),
        Text(
          'Opis oglasa',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: boje.A,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.flag_outlined,
            color: Colors.redAccent,
            size: 30,
          ),
          tooltip: "Prijavi oglas",
          onPressed: () {
            _prikaziDijalogZaPrijavuOglasa(context, boje);
          },
        ),
      ],
    );
  }

  Widget _buildJobTitleHeader(QuickJobsColors boje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: boje.A,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        oglas.naslov,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: boje.bg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(QuickJobsColors boje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Detaljni opis posla:",
            style: TextStyle(
              color: boje.A?.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            oglas.opis.isEmpty ? 'Nema opisa.' : oglas.opis,
            style: TextStyle(color: boje.A, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  void _showSnack(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSquareImage(QuickJobsColors boje) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: boje.bg?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: boje.A!, width: 1.5),
      ),
      child: Icon(Icons.image, color: boje.A, size: 30),
    );
  }

  Widget _buildDetailRow(
    String text,
    IconData icon,
    QuickJobsColors boje, {
    IconData? trailingIcon,
    VoidCallback? onTap,
  }) {
    final rowContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: boje.A, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: boje.A,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 10),
            Icon(trailingIcon, color: boje.A, size: 20),
          ],
        ],
      ),
    );

    if (onTap == null) return rowContent;

    return GestureDetector(onTap: onTap, child: rowContent);
  }

  void _prikaziDijalogZaPrijavuOglasa(
    BuildContext context,
    QuickJobsColors boje,
  ) {
    String odabraniRazlog = "Scam / Prijevara";
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: boje.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                "Prijavi oglas",
                style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Odaberite razlog zašto prijavljujete ovaj oglas:",
                style: TextStyle(color: boje.A),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: odabraniRazlog,
                dropdownColor: boje.C,
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: boje.C,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    [
                          "Scam / Prijevara",
                          "Lažni oglas",
                          "Neprimjeren sadržaj",
                          "Ostalo",
                        ]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: TextStyle(color: boje.A)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setDialogState(() => odabraniRazlog = v!),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: komentarController,
                maxLines: 3,
                style: TextStyle(color: boje.A),
                decoration: InputDecoration(
                  hintText: "Opišite detaljnije (opcionalno)...",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: boje.C,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Odustani", style: TextStyle(color: boje.A)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: boje.A,
                foregroundColor: boje.bg,
              ),
              onPressed: () async {
                try {
                  await _reportService.prijaviOglas(
                    oglasId: oglas.id,
                    razlog: odabraniRazlog,
                    komentar: komentarController.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _showSnack(
                      context,
                      "Oglas prijavljen. Hvala na povratnoj informaciji!",
                      isError: false,
                    );
                  }
                } catch (e) {
                  debugPrint("Greška pri slanju reporta: $e");
                }
              },
              child: const Text("Pošalji"),
            ),
          ],
        ),
      ),
    );
  }
}
