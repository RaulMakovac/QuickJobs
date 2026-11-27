import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;
    final bool imaLokaciju =
        (oglas.lat != null && oglas.lng != null) ||
        oglas.adresa.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          bottom: false,
          child: jeWeb
              ? _buildWebView(context, boje, isDark, imaLokaciju)
              : _buildMobileView(context, boje, imaLokaciju),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
    bool imaLokaciju,
  ) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.08)
        : (boje.A ?? Colors.black).withValues(alpha: 0.10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: (boje.C ?? boje.B)?.withValues(alpha: 1.0),
            border: Border(
              bottom: BorderSide(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                    tooltip: 'Natrag',
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Opis oglasa',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: boje.A,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.flag_outlined,
                  color: Colors.redAccent,
                  size: 28,
                ),
                tooltip: "Prijavi oglas",
                onPressed: () => _prikaziDijalogZaPrijavuOglasa(context, boje),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: boxPozadina,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (boje.A ?? Colors.black).withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                    ),
                  ),
                  child: _buildDetaljiSadrzaj(
                    context,
                    boje,
                    imaLokaciju,
                    pokaziMobilniAppBar: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    QuickJobsColors boje,
    bool imaLokaciju,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 200),
      child: _buildDetaljiSadrzaj(
        context,
        boje,
        imaLokaciju,
        pokaziMobilniAppBar: true,
      ),
    );
  }

  Widget _buildDetaljiSadrzaj(
    BuildContext context,
    QuickJobsColors boje,
    bool imaLokaciju, {
    required bool pokaziMobilniAppBar,
  }) {
    return Column(
      children: [
        if (pokaziMobilniAppBar) ...[
          _buildAppBar(context, boje),
          const SizedBox(height: 35),
        ],
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
      final adresa = oglas.adresa.trim();
      try {
        if (!kIsWeb) {
          final lokacije = await locationFromAddress(adresa);
          if (lokacije.isNotEmpty) {
            tocka = LatLng(lokacije.first.latitude, lokacije.first.longitude);
          }
        }

        if (tocka == null) {
          final uri = Uri.https(
            'nominatim.openstreetmap.org',
            '/search',
            {
              'q': adresa,
              'format': 'json',
              'limit': '1',
            },
          );
          final response = await http.get(
            uri,
            headers: {
              'User-Agent': 'QuickJobsApp/1.0 (contact@quickjobs.hr)',
            },
          );
          if (response.statusCode == 200) {
            final results = jsonDecode(response.body) as List<dynamic>;
            if (results.isNotEmpty) {
              final first = results.first as Map<String, dynamic>;
              final lat = double.tryParse(first['lat']?.toString() ?? '');
              final lon = double.tryParse(first['lon']?.toString() ?? '');
              if (lat != null && lon != null) {
                tocka = LatLng(lat, lon);
              }
            }
          }
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
    final MapController kartaController = MapController();
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    Widget buildKartaPanel(BuildContext panelContext) {
      return Column(
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
                  tooltip: 'Centriraj na lokaciju',
                  onPressed: () {
                    kartaController.move(prikazanaTocka, 15.5);
                  },
                  icon: Icon(Icons.my_location_rounded, color: boje.A),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(panelContext),
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
                  mapController: kartaController,
                  options: MapOptions(
                    initialCenter: prikazanaTocka,
                    initialZoom: 15.5,
                    onMapReady: () {
                      kartaController.move(prikazanaTocka, 15.5);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.quickjobs.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: prikazanaTocka,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: const Icon(
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
      );
    }

    if (jeWeb) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Lokacija oglasa',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (dialogContext, _, __) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                color: boje.bg,
                elevation: 14,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: (boje.A ?? Colors.black).withValues(alpha: 0.22),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: 780,
                  height: 560,
                  child: buildKartaPanel(dialogContext),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
      return;
    }

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
          child: buildKartaPanel(modalContext),
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
    final bool dugNaslov = oglas.naslov.trim().length > 42;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: dugNaslov ? 20 : 14,
      ),
      decoration: BoxDecoration(
        color: boje.A,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        oglas.naslov,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: boje.bg,
          fontSize: dugNaslov ? 18 : 20,
          fontWeight: FontWeight.bold,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(QuickJobsColors boje) {
    final String tekstOpisa = oglas.opis.trim().isEmpty
        ? 'Nema opisa.'
        : oglas.opis.trim();
    final bool dugOpis = tekstOpisa.length > 220;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: dugOpis ? 140 : 88),
      padding: EdgeInsets.all(dugOpis ? 24 : 18),
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Detaljni opis posla:",
            style: TextStyle(
              color: boje.A?.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          SizedBox(height: dugOpis ? 10 : 6),
          Text(
            tekstOpisa,
            style: TextStyle(
              color: boje.A,
              fontSize: 15,
              height: dugOpis ? 1.5 : 1.35,
            ),
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
    final bool viseredniTekst = text.trim().length > 36;

    final rowContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: viseredniTekst ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: viseredniTekst
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
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
                height: viseredniTekst ? 1.35 : 1.2,
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
