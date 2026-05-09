import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat.dart';

class ChatHub extends StatefulWidget {
  const ChatHub({super.key});

  @override
  State<ChatHub> createState() => _ChatHubState();
}

class _ChatHubState extends State<ChatHub> {
  final supabase = Supabase.instance.client;

  /// 1. Ovdje smo maknuli mojId jer ti ne treba, RLS radi filter
  Stream<List<Map<String, dynamic>>> _dohvatiMojeSobe() {
    return supabase
        .from('chat_sobe')
        .stream(primaryKey: ['id'])
        .eq('status', 'aktivno') // Samo aktivne sobe
        .order('created_at', ascending: false);
  }

  // 2. Popravljen dohvat s ispisom greške u konzolu
  Future<Map<String, dynamic>> _dohvatiPodatkeZaKarticu(Map<String, dynamic> soba) async {
    try {
      final mojId = supabase.auth.currentUser!.id;
      
      // Koristimo ?? '' da izbjegnemo crash ako je ID slučajno null
      final klijentId = soba['klijent_id'] ?? '';
      final radnikId = soba['radnik_id'] ?? '';
      
      final sugovornikId = klijentId == mojId ? radnikId : klijentId;

      if (sugovornikId == '') {
        return {'puno_ime': 'Soba bez korisnika', 'naslov_oglasa': 'Info', 'zadnja_poruka': ''};
      }

      // Dohvaćamo podatke jedan po jedan da budemo sigurni
      final profilRes = await supabase.from('profiles').select('puno_ime').eq('id', sugovornikId).maybeSingle();
      final oglasRes = await supabase.from('oglasi').select('naslov_oglasa').eq('id', soba['oglas_id']).maybeSingle();
      final porukaRes = await supabase.from('poruke')
          .select('tekst')
          .eq('soba_id', soba['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return {
        'puno_ime': profilRes?['puno_ime'] ?? 'Nepoznat korisnik',
        'naslov_oglasa': oglasRes?['naslov_oglasa'] ?? 'Oglas uklonjen',
        'zadnja_poruka': porukaRes?['tekst'] ?? 'Započnite razgovor...',
      };
    } catch (e) {
      // OVO JE KLJUČNO: Pogledaj u Debug Console u VS Code-u što piše!
      print("SUPABASE GREŠKA: $e"); 
      return {
        'puno_ime': 'Greška u bazi',
        'naslov_oglasa': '!',
        'zadnja_poruka': e.toString(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    const bojaPozadine = Color(0xFFE5D9D6);
    const tamnoSmedja = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: bojaPozadine,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(tamnoSmedja),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Vaši aktivni razgovori s radnicima i klijentima.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _dohvatiMojeSobe(),
                builder: (context, snapshot) {
                  // Provjera stanja veze
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.brown));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text("Greška: Provjerite Realtime postavke"));
                  }

                  final sobe = snapshot.data ?? [];
                  
                  if (sobe.isEmpty) {
                    return const Center(
                      child: Text("Nemate aktivnih poruka.", style: TextStyle(color: Colors.black45)),
                    );
                  }

                  return ListView.builder(
                    itemCount: sobe.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) => _buildChatTile(sobe[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> soba) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dohvatiPodatkeZaKarticu(soba),
      builder: (context, snapshot) {
        // Ako podaci još dolaze, prikaži suptilni kostur kartice
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
            child: LinearProgressIndicator(color: Colors.brown, minHeight: 0.5),
          );
        }

        final d = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatIndividualni(
                  sobaId: soba['id'],
                  naslovOglasa: d['naslov_oglasa'],
                  imeSugovornika: d['puno_ime'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border(bottom: BorderSide(color: Colors.brown.withOpacity(0.2), width: 0.5)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF8F6E68),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['puno_ime'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        d['zadnja_poruka'], 
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.brown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d['naslov_oglasa'],
                    style: const TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color boja) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          Expanded(
            child: Text(
              "Poruke", 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: boja),
            ),
          ),
          const SizedBox(width: 40), // Balans za back button
        ],
      ),
    );
  }

  Future<void> zavrsiChat(String sobaId) async {
  try {
    await supabase
        .from('chat_sobe')
        .update({
          'status': 'arhivirano',
          'updated_at': DateTime.now().toIso8601String(), // Osvježavamo vrijeme za Cron
        })
        .eq('id', sobaId);
        
    print("Chat je uspješno arhiviran.");
  } catch (e) {
    print("Greška pri arhiviranju: $e");
  }
}
}