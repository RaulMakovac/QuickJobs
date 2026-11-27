import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/prijava_service.dart';
import '../dekor.dart';
import 'oglas.dart';

class MojePrijaveEkran extends StatefulWidget {
  const MojePrijaveEkran({super.key});

  @override
  State<MojePrijaveEkran> createState() => _MojePrijaveEkranState();
}

class _MojePrijaveEkranState extends State<MojePrijaveEkran> {
  final PrijavaService _prijavaService = PrijavaService();
  final supabase = Supabase.instance.client;

  Future<List<Prijava>> _dohvatiMojePrijave() {
    return _prijavaService.dohvatiMojePrijave();
  }

  Future<void> _spremiRecenzijuAutora({
    required Prijava prijava,
    required int ocjena,
    String? komentar,
  }) async {
    try {
      await _prijavaService.spremiRecenzijuAutora(
        prijava: prijava,
        ocjena: ocjena,
        komentar: komentar,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Hvala na ocjeni! Posao je arhiviran."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Greška: $e")));
      }
    }
  }

  void _pokaziDijalogZaOcjenuAutora(Prijava prijava, QuickJobsColors boje) {
    int odabranaOcjena = 5;
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: boje.bg,
          title: Text(
            "Ocijeni poslodavca",
            textAlign: TextAlign.center,
            style: TextStyle(color: boje.A),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Kako ste zadovoljni suradnjom na oglasu:\n'${prijava.oglas.naslov}'?",
                textAlign: TextAlign.center,
                style: TextStyle(color: boje.A),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < odabranaOcjena ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 35,
                    ),
                    onPressed: () =>
                        setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: komentarController,
                style: TextStyle(color: boje.A),
                decoration: InputDecoration(
                  hintText: "Napišite iskustvo...",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: boje.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Odustani", style: TextStyle(color: boje.A)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: boje.A),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuAutora(
                  prijava: prijava,
                  ocjena: odabranaOcjena,
                  komentar: komentarController.text,
                );
              },
              child: Text("Spremi", style: TextStyle(color: boje.bg)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _otkaziPrijavu(Prijava prijava, bool zaposlenSam) async {
    try {
      await _prijavaService.otkaziPrijavu(
        prijava: prijava,
        zaposlenSam: zaposlenSam,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: zaposlenSam ? Colors.orange : Colors.green,
            content: Text(
              zaposlenSam
                  ? 'Uspješno ste se odjavili s posla. Chat je arhiviran.'
                  : 'Prijava uspješno povučena.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Greška pri otkazivanju: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      extendBodyBehindAppBar: !jeWeb,
      appBar: jeWeb
          ? null
          : AppBar(
              title: Text(
                "Moje prijave",
                style: TextStyle(color: boje.A, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: boje.A),
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
              Text(
                'Moje prijave',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: boje.A,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Prijava>>(
            future: _dohvatiMojePrijave(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: boje.A),
                );
              }

              final prijave = snapshot.data ?? [];
              if (prijave.isEmpty) {
                return Center(
                  child: Text(
                    "Nema aktivnih prijava.",
                    style: TextStyle(
                      color: boje.A,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                    decoration: BoxDecoration(
                      color: boxPozadina,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (boje.A ?? Colors.black).withValues(
                          alpha: isDark ? 0.18 : 0.12,
                        ),
                      ),
                    ),
                    child: _buildListaPrijave(context, prijave, boje),
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
    return FutureBuilder<List<Prijava>>(
      future: _dohvatiMojePrijave(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: boje.A),
          );
        }

        final prijave = snapshot.data ?? [];
        if (prijave.isEmpty) {
          return Center(
            child: Text(
              "Nema aktivnih prijava.",
              style: TextStyle(
                color: boje.A,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return _buildListaPrijave(context, prijave, boje);
      },
    );
  }

  Widget _buildListaPrijave(
    BuildContext context,
    List<Prijava> prijave,
    QuickJobsColors boje,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      itemCount: prijave.length,
      itemBuilder: (context, index) {
        final prijava = prijave[index];
        final oglas = prijava.oglas;
        final user = supabase.auth.currentUser;

        bool zaposlenSam = oglas.obavljacId == user?.id;
        bool jeZavrseno = oglas.status == 'obavljen';

        final ikonaPosla =
            kategorijeSaIkonama[oglas.kategorija] ?? Icons.hourglass_top;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: zaposlenSam
                ? (jeZavrseno ? boje.B : Colors.green[700])
                : boje.C,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: CircleAvatar(
              backgroundColor: boje.bg?.withValues(alpha: 0.3),
              child: Icon(
                jeZavrseno
                    ? Icons.done_all
                    : (zaposlenSam ? Icons.celebration : ikonaPosla),
                color: boje.A,
              ),
            ),
            title: Text(
              oglas.naslov,
              style: TextStyle(
                color: boje.A,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              jeZavrseno
                  ? "Posao završen"
                  : (zaposlenSam ? "PRIHVAĆENI STE!" : "Na čekanju..."),
              style: TextStyle(color: boje.A?.withValues(alpha: 0.7)),
            ),
            trailing: (jeZavrseno && zaposlenSam)
                ? ElevatedButton(
                    onPressed: () =>
                        _pokaziDijalogZaOcjenuAutora(prijava, boje),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "OCIJENI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  )
                : Icon(Icons.info_outline, color: boje.A),
            onTap: () => _prikaziUpravljanjePrijavom(
              context,
              prijava,
              zaposlenSam,
              jeZavrseno,
              boje,
            ),
          ),
        );
      },
    );
  }

  void _prikaziUpravljanjePrijavom(
    BuildContext context,
    Prijava prijava,
    bool zaposlenSam,
    bool jeZavrseno,
    QuickJobsColors boje,
  ) {
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    Widget buildUpravljanjeSadrzaj(BuildContext overlayContext) {
      return Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                var oglasZaPrikaz = prijava.oglas;

                if (oglasZaPrikaz.autorIme == null ||
                    oglasZaPrikaz.autorIme == 'Nepoznat autor') {
                  final data = await supabase
                      .from('profiles')
                      .select('puno_ime')
                      .eq('id', oglasZaPrikaz.autorId ?? '')
                      .maybeSingle();

                  if (data != null) {
                    oglasZaPrikaz = oglasZaPrikaz.copyWith(
                      autorIme: data['puno_ime'],
                    );
                  }
                }

                if (context.mounted) {
                  Navigator.pop(overlayContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetaljiOglasa(
                        oglas: oglasZaPrikaz,
                        samoPregled: true,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Text(
                    prijava.oglas.naslov,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Dodirni za detalje oglasa",
                    style: TextStyle(
                      fontSize: 12,
                      color: boje.A?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            if (zaposlenSam && !jeZavrseno)
              Text(
                "Odabrani ste! Poslodavac će vas uskoro kontaktirati.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: boje.A,
                ),
              ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: boje.C,
                      foregroundColor: boje.A,
                    ),
                    onPressed: () => Navigator.pop(overlayContext),
                    child: const Text("Zatvori"),
                  ),
                ),
                if (!jeZavrseno) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(overlayContext);
                        _otkaziPrijavu(prijava, zaposlenSam);
                      },
                      child: Text(
                        zaposlenSam ? "Odjavi se s posla" : "Povuci prijavu",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
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
              child: buildUpravljanjeSadrzaj(dialogContext),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: boje.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: buildUpravljanjeSadrzaj(modalContext),
      ),
    );
  }
}