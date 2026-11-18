import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/azuriraj_oglas.dart';
import '../services/oglas_service.dart';
import 'zaposli.dart';
import '../dekor.dart'; 

class MojiOglasi extends StatefulWidget {
  const MojiOglasi({super.key});

  @override
  State<MojiOglasi> createState() => _MojiOglasiState();
}

class _MojiOglasiState extends State<MojiOglasi> {
  final OglasService _oglasService = OglasService();

  Future<List<Oglas>> _dohvatiMojeOglase() {
    return _oglasService.dohvatiMojeOglase();
  }

  void _pokaziDijalogZaOcjenu(Oglas oglas, QuickJobsColors boje) {
    int odabranaOcjena = 5;
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: boje.bg,
          title: Text("Završi i ocijeni", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: boje.A)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ocijenite radnika za obavljeni posao:", textAlign: TextAlign.center, style: TextStyle(color: boje.A)),
              const SizedBox(height: 15),
              Wrap(
                alignment: WrapAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      index < odabranaOcjena ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.orange,
                      size: 34,
                    ),
                    onPressed: () => setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: komentarController,
                style: TextStyle(color: boje.A),
                decoration: InputDecoration(
                  hintText: "Komentar (opcionalno)",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: boje.C,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Odustani", style: TextStyle(color: boje.A))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: boje.A),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _oglasService.spremiRecenzijuIZavrsi(
                    oglas: oglas,
                    ocjena: odabranaOcjena,
                    komentar: komentarController.text,
                  );
                  if (mounted) setState(() {});
                } catch (e) {
                  debugPrint("Greška pri završavanju: $e");
                }
              },
              child: Text("Spremi i završi", style: TextStyle(color: boje.bg)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reaktivirajOglas(String oglasId, String? stariObavljacId) async {
    try {
      await _oglasService.reaktivirajOglas(oglasId, stariObavljacId);
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oglas je uspješno reaktiviran!")),
        );
      }
    } catch (e) {
      debugPrint("Greška pri reaktivaciji: $e");
    }
  }

  void _potvrdiReaktivaciju(Oglas oglas, QuickJobsColors boje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: boje.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Ponovna objava", style: TextStyle(color: boje.A)),
        content: Text("Sigurno želite otkazati trenutnog radnika i ponovno otvoriti oglas '${oglas.naslov}' za nove prijave?", style: TextStyle(color: boje.A)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Ne", style: TextStyle(color: boje.A))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: boje.A),
            onPressed: () { 
              Navigator.pop(context); 
              _reaktivirajOglas(oglas.id, oglas.obavljacId);
            }, 
            child: Text("Da, objavi ponovno", style: TextStyle(color: boje.bg))
          ),
        ],
      ),
    );
  }

  Future<void> _trajnoObrisiOglas(String id) async {
    try {
      await _oglasService.trajnoObrisiOglas(id);
      if (mounted) setState(() {}); 
    } catch (e) {
      debugPrint("Greška pri trajnom brisanju oglasa: $e");
    }
  }

  void _potvrdiBrisanje(Oglas oglas, QuickJobsColors boje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: boje.bg,
        title: Text("Trajno brisanje", style: TextStyle(color: boje.A)),
        content: Text("Jeste li sigurni da želite trajno obrisati oglas '${oglas.naslov}' iz baze podataka?", style: TextStyle(color: boje.A)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Ne", style: TextStyle(color: boje.A))),
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              _trajnoObrisiOglas(oglas.id);
            }, 
            child: const Text("Obriši trajno", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
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
              _buildHeader(boje),
              Expanded(
                child: FutureBuilder<List<Oglas>>(
                  future: _dohvatiMojeOglase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: boje.A));
                    }
                    final oglasi = snapshot.data ?? [];
                    if (oglasi.isEmpty) {
                      return Center(child: Text("Nema oglasa.", style: TextStyle(color: boje.A)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: oglasi.length,
                      itemBuilder: (context, index) => _buildMojOglasCard(oglasi[index], boje),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 20), 
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 26, color: boje.A),
          ),
          Expanded(
            child: Text(
              "Moji oglasi", 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: boje.A),
            ),
          ),
          const SizedBox(width: 48), 
        ],
      ),
    );
  }

  Widget _buildMojOglasCard(Oglas oglas, QuickJobsColors boje) {
    bool imaRadnika = oglas.obavljacId != null;
    bool jeZavrsen = oglas.status == 'obavljen';
    
    bool mozeSeObrisati = !imaRadnika || jeZavrsen; 
    bool mozeSeUrediti = !imaRadnika && !jeZavrsen;  

    final ikonaKategorije = kategorijeSaIkonama[oglas.kategorija] ?? Icons.person_search;

    return Opacity(
      opacity: jeZavrsen ? 0.65 : 1.0, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: jeZavrsen ? boje.B : boje.C,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      backgroundColor: boje.bg?.withValues(alpha: 0.3),
                      radius: 22,
                      child: Icon(ikonaKategorije, color: boje.A, size: 24),
                    ),
                    if (jeZavrsen || imaRadnika)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(color: boje.bg, shape: BoxShape.circle),
                          child: Icon(
                            jeZavrsen ? Icons.check_circle : Icons.engineering,
                            color: jeZavrsen ? boje.A : Colors.orange[800],
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(oglas.naslov, style: TextStyle(color: boje.A, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        jeZavrsen ? "Posao uspješno završen" : (imaRadnika ? "Radnik odabran" : "Tražim radnika..."), 
                        style: TextStyle(color: boje.A?.withValues(alpha: 0.7), fontSize: 13)
                      ),
                    ],
                  ),
                ),
                Text("${oglas.isplata}€", style: TextStyle(color: boje.A, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            Divider(color: boje.A?.withValues(alpha: 0.2), height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (mozeSeObrisati)
                      IconButton(
                        onPressed: () => _potvrdiBrisanje(oglas, boje), 
                        icon: Icon(Icons.delete_outline, color: jeZavrsen ? Colors.red[900] : boje.A)
                      ),
                    if (mozeSeUrediti)
                      IconButton(
                        onPressed: () async {
                          final osvjezi = await Navigator.push(context, MaterialPageRoute(builder: (context) => AzurirajOglas(oglas: oglas)));
                          if (osvjezi == true) setState(() {});
                        },
                        icon: Icon(Icons.edit_outlined, color: boje.A),
                      ),
                  ],
                ),
                if (!jeZavrsen) ...[
                  Row(
                    children: [
                      if (imaRadnika) ...[
                        IconButton(
                          onPressed: () => _potvrdiReaktivaciju(oglas, boje),
                          icon: Icon(Icons.refresh_rounded, color: boje.A, size: 28),
                          tooltip: "Ponovno objavi oglas",
                        ),
                        const SizedBox(width: 4), 
                      ],
                      ElevatedButton(
                        onPressed: () async {
                          if (imaRadnika) {
                            _pokaziDijalogZaOcjenu(oglas, boje);
                          } else {
                            final osvjezi = await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => Zaposli(oglas: oglas))
                            );
                            if (osvjezi == true) {
                              if (mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Radnik je uspješno prihvaćen!"),
                                    backgroundColor: boje.A,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: imaRadnika ? Colors.orange[700] : boje.bg, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: Text(
                          imaRadnika ? "ZAVRŠI POSAO" : "VIDI PRIJAVE", 
                          style: TextStyle(color: imaRadnika ? Colors.white : boje.A)
                        ),
                      ),
                      if (imaRadnika) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/ekrani/chat_hub'), 
                          icon: Icon(Icons.forum_rounded, color: boje.A)
                        ),
                      ],
                    ],
                  ),
                ] else
                  Text("ZAVRŠENO", style: TextStyle(color: boje.A?.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}