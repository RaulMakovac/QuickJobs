import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../dekor.dart';
import 'korisnicki_profil.dart';
import 'glavni_ekran.dart'; 
import 'oglas.dart';       

class ChatIndividualni extends StatefulWidget {
  final String sobaId;
  final String naslovOglasa;
  final String imeSugovornika;
  final String sugovornikId;
  final String oglasId;
  final bool jeArhiviran;

  const ChatIndividualni({
    super.key,
    required this.sobaId,
    required this.naslovOglasa,
    required this.imeSugovornika,
    required this.sugovornikId,
    required this.oglasId,
    required this.jeArhiviran,
  });

  @override
  State<ChatIndividualni> createState() => _ChatIndividualniState();
}

class _ChatIndividualniState extends State<ChatIndividualni> {
  final _porukaController = TextEditingController();
  final supabase = Supabase.instance.client;
  late final String mojId;
Future<Map<String, dynamic>> _dohvatiPodatkeSugovornika() async {
  // Ovo je identična logika kao u Oglas.fromJson
  final data = await supabase
      .from('profiles')
      .select('puno_ime') // Dohvaćamo samo ono što nam treba
      .eq('id', widget.sugovornikId)
      .maybeSingle();
      
  return data ?? {'puno_ime': 'Nepoznati korisnik'};
}
  @override
  void initState() {
    mojId = supabase.auth.currentUser!.id;
    super.initState();
  }

  // --- LOGIKA ZA NAVIGACIJU NA OGLAS UNUTAR CHATA ---
  Future<void> _navigirajNaOglas() async {
    try {
      final res = await supabase.from('oglasi').select().eq('id', widget.oglasId).maybeSingle();
      if (res != null && mounted) {
        final oglasObjekt = Oglas.fromJson(res); 
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetaljiOglasa(oglas: oglasObjekt, samoPregled: true)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Greška pri otvaranju oglasa.")));
    }
  }

  Future<void> _posaljiPoruku(bool chatZakljucan) async {
    if (chatZakljucan) return; // Dvostruka sigurnost
    final tekst = _porukaController.text.trim();
    if (tekst.isEmpty) return;
    _porukaController.clear();
    try {
      await supabase.from('poruke').insert({'soba_id': widget.sobaId, 'posiljatelj_id': mojId, 'tekst': tekst});
      await supabase.from('chat_sobe').update({'updated_at': DateTime.now().toIso8601String()}).eq('id', widget.sobaId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }
//nakon gotovog posla, korisnik može odmah obrisati chat, bez čekanja 30 dana kad se automatski briše (supabase trigger)
  Future<void> _obrisiChatOdmah() async {
    final potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Obriši razgovor?"),
        content: const Text("Želite li odmah trajno obrisati ovaj razgovor?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Ne")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Obriši", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (potvrda == true) {
      await supabase.from('chat_sobe').delete().eq('id', widget.sobaId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // status sobe pratimo direktno iz baze, jer se može promijeniti (arhivirati) i dok je korisnik u chatu, pa tako odmah reagiramo na tu promjenu
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('chat_sobe').stream(primaryKey: ['id']).eq('id', widget.sobaId),
      builder: (context, snapshot) {
        // Provjeravamo status iz baze, ako stream još nije povukao podatke koristi se početni widget.jeArhiviran
        bool arhiviranIzBaze = widget.jeArhiviran;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          arhiviranIzBaze = snapshot.data!.first['status'] == 'arhivirano';
        }

        final bojaHeader = arhiviranIzBaze ? Colors.grey[700]! : const Color(0xFFBFA2A2);
        final bojaPozadine = arhiviranIzBaze ? const Color(0xFFD1CBC9) : const Color(0xFFE5D9D6);

        return Scaffold(
          backgroundColor: bojaPozadine,
          appBar: AppBar(
            toolbarHeight: 90,
            backgroundColor: bojaHeader,
            automaticallyImplyLeading: false,
            elevation: 0,
            actions: [
              if (arhiviranIzBaze)
                IconButton(icon: const Icon(Icons.delete_forever, color: Colors.white), onPressed: _obrisiChatOdmah),
            ],
            title: _buildAppBarTitle(),
          ),
          body: PozadinaKrugovi(
            child: Column(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: arhiviranIzBaze ? 0.6 : 1.0,
                    child: _buildMessagesStream(),
                  ),
                ),
                // Ako je arhiviran, prikaži banner arhiviranosti, inače input polje
                arhiviranIzBaze ? _buildArhiviranBanner() : _buildInputArea(arhiviranIzBaze),
              ],
            ),
          ),
        );
      },
    );
  }

 Widget _buildAppBarTitle() {
  return Row(
    children: [
      IconButton(
        onPressed: () => Navigator.pop(context), 
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22)
      ),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => KorisnickiProfil(prikazaniKorisnikId: widget.sugovornikId))),
        child: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person_outline, color: Colors.black)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- OVDJE DOHVAĆAM IME IZ BAZE ---
            FutureBuilder<Map<String, dynamic>>(
              future: _dohvatiPodatkeSugovornika(),
              builder: (context, snapshot) {
                // Dok se učitava, prikaži ime iz widgeta (da ne bude prazno) nitpick ali izgledalo mi je ružno bez ovog
                final ime = snapshot.hasData ? snapshot.data!['puno_ime'] : widget.imeSugovornika;
                
                return Text(
                  ime, 
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _navigirajNaOglas,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF8F6E68), borderRadius: BorderRadius.circular(15)),
                child: Text(
                  widget.naslovOglasa, 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildMessagesStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('poruke').stream(primaryKey: ['id']).eq('soba_id', widget.sobaId).order('created_at', ascending: false),
      builder: (context, snapshot) {
        final poruke = snapshot.data ?? [];
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: poruke.length,
          itemBuilder: (context, index) => _buildChatBubble(poruke[index]['tekst'], poruke[index]['created_at'], poruke[index]['posiljatelj_id'] == mojId),
        );
      },
    );
  }

  Widget _buildArhiviranBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: const Column(
        children: [
          Icon(Icons.lock_clock_outlined, color: Colors.black45),
          SizedBox(height: 8),
          Text("Razgovor je arhiviran jer je posao završen.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Text("Slanje poruka više nije moguće.", style: TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool zakljucano) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFBEA3A3),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _porukaController,
                enabled: !zakljucano,
                decoration: InputDecoration(
                  hintText: "Upišite poruku...",
                  fillColor: const Color(0xFFE5D9D6),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF4A2C29),
              child: IconButton(
                onPressed: () => _posaljiPoruku(zakljucano), 
                icon: const Icon(Icons.send, color: Colors.white, size: 20)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String tekst, String vrijeme, bool ja) {
    final formatirano = DateFormat('HH:mm').format(DateTime.parse(vrijeme));
    return Align(
      alignment: ja ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ja ? Colors.white : const Color(0xFFC7B1AA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(tekst, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(formatirano, style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}
