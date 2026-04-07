import 'package:flutter/material.dart';
import 'package:quickjobs/ekrani/azuriraj_oglas.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart'; 

class MojiOglasi extends StatefulWidget {
  const MojiOglasi({super.key});

  @override
  State<MojiOglasi> createState() => _MojiOglasiState();
}

class _MojiOglasiState extends State<MojiOglasi> {
  final supabase = Supabase.instance.client;

  // --- LOGIKA: DOHVAĆANJE ---
  Future<List<Oglas>> dohvatiMojeOglase() async {
    final user = supabase.auth.currentUser;
    final response = await supabase
        .from('oglasi')
        .select('*, autor:profiles!oglasi_autor_id_fkey(puno_ime)')
        .eq('autor_id', user!.id) 
        .order('created_at', ascending: false);

    final List data = response as List;
    return data.map((json) => Oglas.fromJson(json)).toList();
  }

  // --- LOGIKA: BRISANJE ---
  Future<void> _obrisiOglas(String id) async {
    try {
      await supabase.from('oglasi').delete().eq('id', id);
      setState(() {}); // Osvježava listu nakon brisanja
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oglas uspješno obrisan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri brisanju: $e')),
        );
      }
    }
  }

  // --- LOGIKA: UPDATE (STATUS) ---
  Future<void> _promijeniStatus(String id, String noviStatus) async {
    try {
      await supabase.from('oglasi').update({'status': noviStatus}).eq('id', id);
      setState(() {});
      if (mounted) Navigator.pop(context); // Zatvara BottomSheet
    } catch (e) {
      print("Greška pri ažuriranju: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: Stack(
        children: [
          Positioned(top: -50, left: -30, child: CircleAvatar(radius: 100, backgroundColor: Colors.white12)),
          Positioned(bottom: -50, right: -30, child: CircleAvatar(radius: 120, backgroundColor: Colors.white12)),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                const Text(
                  "Ovdje možete vidjeti popis poslova koje ste objavili",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<Oglas>>(
                    future: dohvatiMojeOglase(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF4A2C29)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("Niste objavili nijedan oglas."));
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
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, size: 30)),
          const Expanded(
            child: Text("Moji oglasi", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMojOglasCard(Oglas oglas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF8F6E68), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row( 
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 80, height: 80,
                  color: Colors.green[200],
                  child: const Icon(Icons.image, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oglas.naslov, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Status: ${oglas.status}", 
                      style: const TextStyle(color: Colors.white70, fontSize: 14)
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Isplata: ${oglas.isplata}€", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          
          // --- AKCIJE: STATUS, UREDI I OBRIŠI ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 1. Gumb za brzu promjenu STATUSA (otvara BottomSheet)
              TextButton.icon(
                onPressed: () => _pokaziOpcijeUredivanja(oglas),
                icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                label: const Text("Status", style: TextStyle(color: Colors.white)),
              ),
              
              const SizedBox(width: 5),

              // 2. Gumb za EDIT specifikacija (vodi na novi ekran)
              TextButton.icon(
                onPressed: () async {
                  final osvjezi = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AzurirajOglas(oglas: oglas),
                    ),
                  );
                  // Ako se vrati 'true' iz UrediOglasEkran, osvježi listu
                  if (osvjezi == true) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                label: const Text("Uredi", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(width: 5),

              // 3. Gumb za BRISANJE
              IconButton(
                onPressed: () => _potvrdiBrisanje(oglas),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFFB7B7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DIJALOG ZA POTVRDU BRISANJA ---
  void _potvrdiBrisanje(Oglas oglas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Brisanje oglasa"),
        content: Text("Jeste li sigurni da želite trajno obrisati oglas '${oglas.naslov}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Odustani")),
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

  // --- MODAL ZA PROMJENU STATUSA ---
  void _pokaziOpcijeUredivanja(Oglas oglas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE5D9D6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Promijeni status oglasa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _statusTile(oglas.id, "otvoren", Icons.lock_open, Colors.green),
              _statusTile(oglas.id, "u tijeku", Icons.access_time, Colors.orange),
              _statusTile(oglas.id, "obavljen", Icons.check_circle_outline, Colors.blue),
              _statusTile(oglas.id, "neobavljen", Icons.cancel_outlined, Colors.red),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _statusTile(String id, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text("Označi kao '$status'"),
      onTap: () => _promijeniStatus(id, status),
    );
  }
}
