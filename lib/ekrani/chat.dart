import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatIndividualni extends StatefulWidget {
  final String sobaId;
  final String naslovOglasa;
  final String imeSugovornika;

  const ChatIndividualni({
    super.key,
    required this.sobaId,
    required this.naslovOglasa,
    required this.imeSugovornika,
  });

  @override
  State<ChatIndividualni> createState() => _ChatIndividualniState();
}

class _ChatIndividualniState extends State<ChatIndividualni> {
  final _porukaController = TextEditingController();
  final supabase = Supabase.instance.client;
  late final String mojId;

  @override
  void initState() {
    mojId = supabase.auth.currentUser!.id;
    super.initState();
  }

  Future<void> _posaljiPoruku() async {
    final tekst = _porukaController.text.trim();
    if (tekst.isEmpty) return;
    _porukaController.clear();
    try {
      await supabase.from('poruke').insert({
        'soba_id': widget.sobaId,
        'posiljatelj_id': mojId,
        'tekst': tekst,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Greška: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bojaPozadine = Color(0xFFE5D9D6);
    const bojaHeaderNosac = Color(0xFFC7B1AA); // Maknuto 'č'

    return Scaffold(
      backgroundColor: bojaPozadine,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            ),
            const CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Icon(Icons.person_outline, color: Colors.black)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.imeSugovornika, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF8F6E68), borderRadius: BorderRadius.circular(20)),
                    child: Text(widget.naslovOglasa, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.phone, color: Colors.black)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase.from('poruke').stream(primaryKey: ['id']).eq('soba_id', widget.sobaId).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final poruke = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: poruke.length,
                  itemBuilder: (context, index) {
                    final p = poruke[index];
                    return _buildChatBubble(p['tekst'], p['created_at'], p['posiljatelj_id'] == mojId);
                  },
                );
              },
            ),
          ),
          _buildInputArea(bojaHeaderNosac),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String tekst, String vrijeme, bool ja) {
    final formatirano = DateFormat('HH:mm').format(DateTime.parse(vrijeme));
    return Align(
      alignment: ja ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ja ? Colors.white : const Color(0xFFC7B1AA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(tekst),
            Text(formatirano, style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color pozadina) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: pozadina,
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.add),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _porukaController,
                decoration: InputDecoration(
                  hintText: "Poruka...",
                  fillColor: const Color(0xFFE5D9D6),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(onPressed: _posaljiPoruku, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}