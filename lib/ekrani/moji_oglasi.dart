import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/azuriraj_oglas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';
import 'zaposli.dart';

class MojiOglasi extends StatefulWidget {
  const MojiOglasi({super.key});

  @override
  State<MojiOglasi> createState() => _MojiOglasiState();
}

class _MojiOglasiState extends State<MojiOglasi> {
  final supabase = Supabase.instance.client;

  // --- LOGIKA: DOHVAĆANJE MOJIH OGLASA ---
  Future<List<Oglas>> dohvatiMojeOglase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('oglasi')
          .select(
            '*, autor:profiles!oglasi_autor_id_fkey(puno_ime), obavljac:profiles!oglasi_obavljac_id_fkey(puno_ime)',
          )
          .eq('autor_id', user.id)
          .order('created_at', ascending: false);

      final List data = response as List;
      return data.map((json) => Oglas.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Greška pri dohvaćanju: $e");
      return [];
    }
  }

  // --- LOGIKA: DIJALOG ZA OCJENJIVANJE ---
  void _pokaziDijalogZaOcjenu(Oglas oglas) {
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
          title: const Text("Završi i ocijeni", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ocijenite radnika za obavljeni posao:"),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < odabranaOcjena ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => odabranaOcjena = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: komentarController,
                decoration: InputDecoration(
                  hintText: "Komentar (opcionalno)",
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
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F6E68),
              ),
              onPressed: () {
                Navigator.pop(context);
                _spremiRecenzijuIZavrsi(
                  oglas: oglas,
                  ocjena: odabranaOcjena,
                  komentar: komentarController.text,
                );
              },
              child: const Text(
                "Spremi i završi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA: SPREMANJE RECENZIJE I UPDATE OGLASA ---
  Future<void> _spremiRecenzijuIZavrsi({
    required Oglas oglas,
    required int ocjena,
    String? komentar,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null || oglas.obavljacId == null) return;

      // 1. Ubacivanje u tablicu recenzije
      await supabase.from('recenzije').insert({
        'oglas_id': oglas.id,
        'ocjenjivac_id': user.id,
        'ocijenjeni_id': oglas.obavljacId,
        'uloga_ocijenjenog': 'obavljač',
        'ocjena': ocjena,
        'komentar': komentar,
      });

      // 2. Promjena statusa oglasa
      await supabase
          .from('oglasi')
          .update({'status_oglasa': 'obavljen'})
          .eq('id', oglas.id);

      if (mounted) {
        setState(() {}); // Osvježava UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Posao završen i radnik ocijenjen!"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Greška: $e");
    }
  }

  // --- LOGIKA: BRISANJE ---
  Future<void> _obrisiOglas(String id) async {
    try {
      await supabase.from('oglasi').delete().eq('id', id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oglas uspješno obrisan.')),
        );
      }
    } catch (e) {
      debugPrint("Greška: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFE5D9D6);
    const darkBrown = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -30,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -30,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Upravljajte svojim oglasima, zapošljavajte radnike i završavajte poslove na jednom mjestu.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<Oglas>>(
                    future: dohvatiMojeOglase(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: darkBrown),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("Niste objavili nijedan oglas."),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return _buildMojOglasCard(snapshot.data![index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 25),
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMojOglasCard(Oglas oglas) {
    bool imaRadnika = oglas.obavljacId != null;
    bool jeZavrsen = oglas.status == 'obavljen';
    bool mozeSeMijenjati = !imaRadnika && !jeZavrsen;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: jeZavrsen ? Colors.grey[400] : const Color(0xFF8F6E68),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: jeZavrsen
                      ? Colors.black26
                      : (imaRadnika ? Colors.orange[300] : Colors.white24),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  jeZavrsen
                      ? Icons.done_all
                      : (imaRadnika ? Icons.engineering : Icons.person_search),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oglas.naslov,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jeZavrsen
                          ? "Status: Završeno"
                          : (imaRadnika
                                ? "U tijeku: Radnik odabran"
                                : "Tražim radnika..."),
                      style: TextStyle(
                        color: jeZavrsen ? Colors.black45 : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${oglas.isplata}€",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 25, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (mozeSeMijenjati)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _potvrdiBrisanje(oglas),
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Color(0xFFFFB7B7),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final osvjezi = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AzurirajOglas(oglas: oglas),
                          ),
                        );
                        if (osvjezi == true) setState(() {});
                      },
                      icon: const Icon(Icons.edit_note, color: Colors.white),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    jeZavrsen ? "Arhivirano" : "Posao u tijeku",
                    style: const TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (!jeZavrsen)
                ElevatedButton(
                  onPressed: () async {
                    // DODANO: async
                    if (imaRadnika) {
                      _pokaziDijalogZaOcjenu(oglas);
                    } else {
                      // DODANO: await i hvatanje rezultata (osvjezi)
                      final osvjezi = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Zaposli(oglas: oglas),
                        ),
                      );

                      // Ako se vratiš s ekrana Zaposli i rezultat je true, osvježi listu
                      if (osvjezi == true && mounted) {
                        setState(() {});
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: imaRadnika
                        ? Colors.orange[400]
                        : Colors.white,
                    foregroundColor: imaRadnika
                        ? Colors.white
                        : const Color(0xFF4A2C29),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    imaRadnika ? "ZAVRŠI POSAO" : "VIDI PRIJAVE",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _potvrdiBrisanje(Oglas oglas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Brisanje oglasa"),
        content: Text("Želite li trajno ukloniti oglas '${oglas.naslov}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Odustani"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _obrisiOglas(oglas.id);
            },
            child: const Text("Obriši", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
