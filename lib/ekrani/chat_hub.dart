import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat.dart'; 
import '../dekor.dart';

class ChatHub extends StatefulWidget {
  const ChatHub({super.key});

  @override
  State<ChatHub> createState() => _ChatHubState();
}

class _ChatHubState extends State<ChatHub> {
  final supabase = Supabase.instance.client;

  // Stream koji dohvaća sve sobe (uključujući arhivirane)
  Stream<List<Map<String, dynamic>>> _dohvatiMojeSobe() {
    return supabase
        .from('chat_sobe')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false);
  }

  Future<Map<String, dynamic>> _dohvatiPodatkeZaKarticu(Map<String, dynamic> soba) async {
    try {
      final mojId = supabase.auth.currentUser!.id;
      final sugovornikId = soba['klijent_id'] == mojId ? soba['radnik_id'] : soba['klijent_id'];

      if (sugovornikId == null || sugovornikId == '') {
        return {'puno_ime': 'Soba bez korisnika', 'naslov_oglasa': 'Info', 'zadnja_poruka': '', 'sugovornik_id': ''};
      }

      final profilRes = await supabase.from('profiles').select('puno_ime').eq('id', sugovornikId).maybeSingle();
      final oglasRes = await supabase.from('oglasi').select('naslov_oglasa').eq('id', soba['oglas_id']).maybeSingle();
      final porukaRes = await supabase.from('poruke').select('tekst').eq('soba_id', soba['id']).order('created_at', ascending: false).limit(1).maybeSingle();

      return {
        'puno_ime': profilRes?['puno_ime'] ?? 'Nepoznat korisnik',
        'naslov_oglasa': oglasRes?['naslov_oglasa'] ?? 'Oglas uklonjen',
        'zadnja_poruka': porukaRes?['tekst'] ?? 'Započnite razgovor...',
        'sugovornik_id': sugovornikId,
      };
    } catch (e) {
      return {'puno_ime': 'Greška', 'naslov_oglasa': '!', 'zadnja_poruka': 'Provjerite vezu', 'sugovornik_id': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(tamnoSmedja),
              const Text("Vaši razgovori", style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _dohvatiMojeSobe(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.brown));
                    }
                    final sobe = snapshot.data ?? [];
                    if (sobe.isEmpty) return const Center(child: Text("Nemate poruka."));
                    
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
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> soba) {
    final bool jeArhiviran = soba['status'] == 'arhivirano';

    return FutureBuilder<Map<String, dynamic>>(
      future: _dohvatiPodatkeZaKarticu(soba),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 80);
        final d = snapshot.data!;
        
        return Opacity(
          opacity: jeArhiviran ? 0.6 : 1.0,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatIndividualni(
                  sobaId: soba['id'],
                  naslovOglasa: d['naslov_oglasa'],
                  imeSugovornika: d['puno_ime'],
                  sugovornikId: d['sugovornik_id'],
                  oglasId: soba['oglas_id'],
                  jeArhiviran: jeArhiviran,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: jeArhiviran ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
                border: jeArhiviran ? Border.all(color: Colors.black12) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: jeArhiviran ? Colors.grey : const Color(0xFF8F6E68),
                    child: Icon(jeArhiviran ? Icons.archive : Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['puno_ime'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(jeArhiviran ? "Razgovor završen" : d['zadnja_poruka'], 
                             style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1),
                      ],
                    ),
                  ),
                  Text(d['naslov_oglasa'], style: const TextStyle(color: Colors.brown, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
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
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, size: 22)),
          Expanded(child: Text("Poruke", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: boja))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
