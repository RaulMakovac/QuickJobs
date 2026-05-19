import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/azuriraj_oglas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';
import 'zaposli.dart';
import '../dekor.dart'; // Ovdje se nalazi naša zajednička mapa kategorijeSaIkonama

class MojiOglasi extends StatefulWidget {
  const MojiOglasi({super.key});

  @override
  State<MojiOglasi> createState() => _MojiOglasiState();
}

class _MojiOglasiState extends State<MojiOglasi> {
  final supabase = Supabase.instance.client;

  // --- LOGIKA: DOHVAĆANJE I SORTIRANJE (Gotovi idu na dno) ---
  Future<List<Oglas>> dohvatiMojeOglase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('oglasi')
          .select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime), obavljac:profiles!oglasi_obavljac_id_fkey(puno_ime)')
          .eq('autor_id', user.id)
          .eq('je_aktivno', true)
          .order('created_at', ascending: false);

      final List data = response as List;
      List<Oglas> sviOglasi = data.map((json) => Oglas.fromJson(json)).toList();

      // Prvo aktivni, pa obavljeni
      sviOglasi.sort((a, b) {
        if (a.status == 'obavljen' && b.status != 'obavljen') return 1;
        if (a.status != 'obavljen' && b.status == 'obavljen') return -1;
        return 0;
      });

      return sviOglasi;
    } catch (e) {
      debugPrint("Greška pri dohvaćanju: $e");
      return [];
    }
  }

  // --- LOGIKA: DIJALOG ZA OCJENJIVANJE (POPRAVLJEN OVERFLOW) ---
  void _pokaziDijalogZaOcjenu(Oglas oglas) {
    int odabranaOcjena = 5;
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: const Color(0xFFE5D9D6),
          title: const Text("Završi i ocijeni", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ocijenite radnika za obavljeni posao:", textAlign: TextAlign.center),
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
                decoration: InputDecoration(
                  hintText: "Komentar (opcionalno)",
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Odustani")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2C29)),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuIZavrsi(oglas: oglas, ocjena: odabranaOcjena, komentar: komentarController.text);
              },
              child: const Text("Spremi i završi", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA: ZAKLJUČIVANJE POSLA I CHATA ---
  Future<void> _spremiRecenzijuIZavrsi({required Oglas oglas, required int ocjena, String? komentar}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || oglas.obavljacId == null) return;

      await supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.obavljacId,
        'uloga_ocijenjenog': 'obavljač',
        'ocjena': ocjena,
        'komentar': komentar,
      });

      await supabase.from('oglasi').update({'status_oglasa': 'obavljen'}).eq('id', oglas.id);
      await supabase.from('chat_sobe').update({'status': 'arhivirano'}).eq('oglas_id', oglas.id);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Greška pri završavanju: $e");
    }
  }

 Future<void> _obrisiOglas(String id) async {
  try {
    // Umjesto .delete(), radimo .update() jer su podaci povezani s drugim tablicama (prijave, chat sobe, recenzije)
    await supabase
        .from('oglasi')
        .update({'je_aktivno': false}) // Oglas ostaje u bazi, ali se "gasi"
        .eq('id', id);

    // Osvježi ekran (UI će se automatski ažurirati jer ga filtriramo u nastavku)
    setState(() {}); 
  } catch (e) {
    debugPrint("Greška pri brisanju oglasa: $e");
  }
}

  void _potvrdiBrisanje(Oglas oglas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje oglasa"),
        content: Text("Želite li obrisati '${oglas.naslov}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ne")),
          TextButton(onPressed: () { Navigator.pop(context); _obrisiOglas(oglas.id); }, child: const Text("Obriši", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FutureBuilder<List<Oglas>>(
                  future: dohvatiMojeOglase(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final oglasi = snapshot.data ?? [];
                    if (oglasi.isEmpty) return const Center(child: Text("Nema oglasa."));
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: oglasi.length,
                      itemBuilder: (context, index) => _buildMojOglasCard(oglasi[index]),
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

 Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(10, 20, 20, 20), 
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new, 
            size: 26, 
            color: Color(0xFF4A2C29), 
          ),
        ),
        const Expanded(
          child: Text(
            "Moji oglasi", 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 26, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF4A2C29),
            ),
          ),
        ),
        const SizedBox(width: 48), 
      ],
    ),
  );
}

  Widget _buildMojOglasCard(Oglas oglas) {
    bool imaRadnika = oglas.obavljacId != null;
    bool jeZavrsen = oglas.status == 'obavljen';
    bool mozeSeObrisati = !imaRadnika || jeZavrsen;
    bool mozeSeUrediti = !imaRadnika && !jeZavrsen;

    // Dohvaćanje ikone kategorije iz dekor.dart
    final ikonaKategorije = kategorijeSaIkonama[oglas.kategorija] ?? Icons.person_search;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: jeZavrsen ? Colors.grey[400] : const Color(0xFF8F6E68),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // DINAMIČKI PRIKAZ IKONE S MINI STATUS BADGE-OM
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 22,
                    child: Icon(ikonaKategorije, color: Colors.black87, size: 24),
                  ),
                  if (jeZavrsen || imaRadnika)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          jeZavrsen ? Icons.check_circle : Icons.engineering,
                          color: jeZavrsen ? Colors.grey[700] : Colors.orange[800],
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
                    Text(oglas.naslov, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(jeZavrsen ? "Posao završen" : (imaRadnika ? "Radnik odabran" : "Tražim radnika..."), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Text("${oglas.isplata}€", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (mozeSeObrisati)
                    IconButton(onPressed: () => _potvrdiBrisanje(oglas), icon: const Icon(Icons.delete_outline, color: Color(0xFF4A2C29))),
                  if (mozeSeUrediti)
                    IconButton(
                      onPressed: () async {
                        final osvjezi = await Navigator.push(context, MaterialPageRoute(builder: (context) => AzurirajOglas(oglas: oglas)));
                        if (osvjezi == true) setState(() {});
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    ),
                ],
              ),
              if (!jeZavrsen)
                ElevatedButton(
                  onPressed: () async {
                    if (imaRadnika) {
                      _pokaziDijalogZaOcjenu(oglas);
                    } else {
                      final osvjezi = await Navigator.push(context, MaterialPageRoute(builder: (context) => Zaposli(oglas: oglas)));
                      if (osvjezi == true) setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: imaRadnika ? Colors.orange[700] : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(imaRadnika ? "ZAVRŠI POSAO" : "VIDI PRIJAVE", style: TextStyle(color: imaRadnika ? Colors.white : Colors.black)),
                )
              else
                const Text("ARHIVIRANO", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold, fontSize: 12)),
              if (imaRadnika && !jeZavrsen)
                IconButton(onPressed: () => Navigator.pushNamed(context, '/ekrani/chat_hub'), icon: const Icon(Icons.forum_rounded, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}