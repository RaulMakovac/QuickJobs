import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart'; 

class MojePrijaveEkran extends StatefulWidget {
  const MojePrijaveEkran({super.key});

  @override
  State<MojePrijaveEkran> createState() => _MojePrijaveEkranState();
}

class _MojePrijaveEkranState extends State<MojePrijaveEkran> {
  final supabase = Supabase.instance.client;

  // 1. DOHVAĆANJE PRIJAVA
  Future<List<Prijava>> _dohvatiMojePrijave() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    // PAZI: Provjeri zove li se tablica 'prijave' ili 'prijave_na_oglas'
    final response = await supabase
        .from('prijave') 
        .select('*, oglasi(*)') 
        .eq('korisnik_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Prijava.fromJson(json)).toList();
  }

  // 2. FUNKCIJA ZA OTKAZIVANJE (BRISANJE)
  Future<void> _otkaziPrijavu(String prijavaId) async {
    try {
      await supabase.from('prijave').delete().eq('id', prijavaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prijava uspješno otkazana')),
        );
        setState(() {}); // Osvježava listu
      }
    } catch (e) {
      debugPrint("Greška pri brisanju: $e");
    }
  }

  // 3. OVERLAY (BOTTOM SHEET)
  void _prikaziUpravljanjePrijavom(BuildContext context, Prijava prijava) {
    final oglas = prijava.oglas;
    const darkBrown = Color(0xFF4A2C29);
    const cardColor = Color(0xFF8F6E68);
    const bgColor = Color(0xFFE5D9D6);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: darkBrown.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Text(oglas.naslov, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBrown)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
                child: Text("Status: ${oglas.status.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              _buildOverlayInfoTile(Icons.location_on, "Lokacija", oglas.adresa),
              _buildOverlayInfoTile(Icons.payments, "Isplata", "${oglas.isplata}€"),
              _buildOverlayInfoTile(Icons.description, "Opis", oglas.opis),
              _buildOverlayInfoTile(Icons.calendar_today, "Prijavljeno", "${prijava.createdAt.day}.${prijava.createdAt.month}.${prijava.createdAt.year}."),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: darkBrown, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("Zatvori", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _otkaziPrijavu(prijava.id);
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("Odustani", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverlayInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A2C29), size: 24),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkBrown = Color(0xFF4A2C29);
    const bgColor = Color(0xFFE5D9D6);
    const cardColor = Color(0xFF8F6E68);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Prijavljeni poslovi", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBrown),
      ),
      body: FutureBuilder<List<Prijava>>(
        future: _dohvatiMojePrijave(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: darkBrown));
          }
          if (snapshot.hasError) return Center(child: Text("Greška: ${snapshot.error}"));

          final prijave = snapshot.data ?? [];
          if (prijave.isEmpty) return const Center(child: Text("Niste se prijavili ni na jedan posao.", style: TextStyle(color: Colors.black54)));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: prijave.length,
            itemBuilder: (context, index) {
              final prijava = prijave[index];
              final oglas = prijava.oglas;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.work_outline, color: Colors.white)),
                  title: Text(oglas.naslov, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Isplata: ${oglas.isplata}€", style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () => _prikaziUpravljanjePrijavom(context, prijava), // AKTIVACIJA OVERLAYA
                ),
              );
            },
          );
        },
      ),
    );
  }
}