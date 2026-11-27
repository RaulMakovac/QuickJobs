import 'package:flutter/material.dart';
import '../services/zaposli_service.dart';
import '../services/oglas_service.dart';
import '/ekrani/korisnicki_profil.dart';
import '../dekor.dart';

class Zaposli extends StatefulWidget {
  final Oglas oglas;

  const Zaposli({super.key, required this.oglas});

  @override
  State<Zaposli> createState() => _ZaposliState();
}

class _ZaposliState extends State<Zaposli> {
  final ZaposliService _zaposliService = ZaposliService();
  late Future<List> _prijaveFuture;

  @override
  void initState() {
    super.initState();
    _ucitajPrijave();
  }

  void _ucitajPrijave() {
    _prijaveFuture = _zaposliService.dohvatiPrijavljeneKorisnike(
      widget.oglas.id,
    );
  }

  Future<void> _prihvatiKandidata(String kandidatId) async {
    try {
      await _zaposliService.prihvatiKandidata(
        oglasId: widget.oglas.id,
        kandidatId: kandidatId,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("QuickJobs KATASTROFA pri prihvaćanju: $e");
    }
  }

  Future<void> _odbijKandidata(String kandidatId) async {
    try {
      final obrisaniRedci = await _zaposliService.odbijKandidata(
        oglasId: widget.oglas.id,
        kandidatId: kandidatId,
      );

      if (mounted) {
        setState(() {
          _ucitajPrijave();
        });

        if (obrisaniRedci.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Baza je odbila brisanje! Provjeri RLS politiku."),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kandidat uspješno odbijen."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("QuickJobs Greška pri odbijanju: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      appBar: jeWeb
          ? null
          : AppBar(
              title: Text(widget.oglas.naslov),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: boje.A,
            ),
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(context, boje, isDark)
              : _buildMobileView(context, boje),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
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
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                tooltip: 'Natrag',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.oglas.naslov,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: boje.A,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List>(
            future: _prijaveFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: boje.A),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Greška: ${snapshot.error}",
                    style: TextStyle(color: boje.A),
                  ),
                );
              }

              final prijave = snapshot.data ?? [];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: boxPozadina,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (boje.A ?? Colors.black).withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                      ),
                    ),
                    child: _buildPrijaveSadrzaj(
                      context,
                      boje,
                      prijave,
                      jeWeb: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, QuickJobsColors boje) {
    return FutureBuilder<List>(
      future: _prijaveFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: boje.A));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Greška: ${snapshot.error}",
              style: TextStyle(color: boje.A),
            ),
          );
        }

        final prijave = snapshot.data ?? [];
        return _buildPrijaveSadrzaj(
          context,
          boje,
          prijave,
          jeWeb: false,
        );
      },
    );
  }

  Widget _buildPrijaveSadrzaj(
    BuildContext context,
    QuickJobsColors boje,
    List prijave, {
    required bool jeWeb,
  }) {
    final brojPrijava = prijave.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: EdgeInsets.all(jeWeb ? 0 : 20),
          decoration: BoxDecoration(
            color: boje.C,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ukupno prijava: $brojPrijava",
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Pregledajte kandidate ispod",
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(Icons.group, color: boje.A, size: 40),
            ],
          ),
        ),
        SizedBox(height: jeWeb ? 20 : 0),
        Text(
          "LISTA KANDIDATA",
          style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
        ),
        Divider(
          indent: 50,
          endIndent: 50,
          color: boje.A?.withValues(alpha: 0.2),
        ),
        Expanded(
          child: prijave.isEmpty
              ? Center(
                  child: Text(
                    "Još nema prijava.",
                    style: TextStyle(color: boje.A),
                  ),
                )
              : ListView.builder(
                  itemCount: prijave.length,
                  itemBuilder: (context, index) {
                    final profil = prijave[index]['profiles'];

                    return Card(
                      color: boje.C,
                      margin: EdgeInsets.symmetric(
                        horizontal: jeWeb ? 0 : 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: boje.bg,
                          child: Icon(Icons.person, color: boje.A),
                        ),
                        title: Text(
                          profil['puno_ime'] ?? "Korisnik",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: boje.A,
                          ),
                        ),
                        subtitle: Text(
                          "Ocjena: ${profil['ocjena_korisnika'] ?? '0.0'} ★",
                          style: TextStyle(
                            color: boje.A?.withValues(alpha: 0.7),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: boje.A,
                        ),
                        onTap: () =>
                            _prikaziDetaljeKandidata(context, profil, boje),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _prikaziDetaljeKandidata(
    BuildContext context,
    Map<String, dynamic> profil,
    QuickJobsColors boje,
  ) {
    final ocjena = profil['ocjena_korisnika'];
    final imaOcjenu = ocjena != null && ocjena > 0;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    Widget buildDetaljiSadrzaj(BuildContext overlayContext) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_circle, size: 60, color: boje.A),
            const SizedBox(height: 10),
            Text(
              profil['puno_ime'] ?? "Korisnik",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
            Text(
              imaOcjenu ? "Ocjena: $ocjena/5 ★" : "Nema recenzija",
              style: TextStyle(color: boje.A?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(overlayContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        KorisnickiProfil(prikazaniKorisnikId: profil['id']),
                  ),
                );
              },
              icon: Icon(Icons.person_search, color: boje.bg),
              label: Text(
                "UVID U PROFIL PRIJAVLJENOG",
                style: TextStyle(color: boje.bg),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: boje.A,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(overlayContext);
                      await _odbijKandidata(profil['id']);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "ODBIJ",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(overlayContext);
                      await _prihvatiKandidata(profil['id']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "PRIHVATI",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 40, color: boje.A?.withValues(alpha: 0.2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, size: 20, color: boje.A),
                const SizedBox(width: 10),
                Text(
                  profil['telefon'] ?? "Nema broja",
                  style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (jeWeb) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: boje.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: buildDetaljiSadrzaj(dialogContext),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: boje.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (modalContext) => buildDetaljiSadrzaj(modalContext),
    );
  }
}