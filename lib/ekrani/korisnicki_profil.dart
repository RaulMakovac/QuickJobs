import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart'; // Provjeri je li putanja do tvog modela Oglas ispravna

// --- MODEL ZA RECENZIJU ---
class Recenzija {
  final String id;
  final String ocjenjivacIme;
  final String oglasNaslov;
  final int ocjena;
  final String? komentar;
  final String uloga;
  final DateTime createdAt;

  Recenzija({
    required this.id,
    required this.ocjenjivacIme,
    required this.oglasNaslov,
    required this.ocjena,
    this.komentar,
    required this.uloga,
    required this.createdAt,
  });

  factory Recenzija.fromJson(Map<String, dynamic> json) {
    final ocjenjivacData = json['ocjenjivac'];
    final oglasData = json['oglasi'];
    return Recenzija(
      id: json['id'],
      ocjenjivacIme: ocjenjivacData != null ? ocjenjivacData['puno_ime'] : 'Korisnik',
      oglasNaslov: oglasData != null ? oglasData['naslov'] : 'Posao',
      ocjena: json['ocjena'],
      komentar: json['komentar'],
      uloga: json['uloga_ocijenjenog'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// --- EKRAN PROFILA ---
class KorisnickiProfil extends StatefulWidget {
  const KorisnickiProfil({super.key});

  @override
  State<KorisnickiProfil> createState() => _KorisnickiProfilState();
}

class _KorisnickiProfilState extends State<KorisnickiProfil> {
  final supabase = Supabase.instance.client;

  // Boje s dizajna
  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);
  static const cardColor = Color(0xFF8F6E68);
  static const inputBg = Color(0xFFD1BDB9);

  // Kontroleri za uređivanje
  late TextEditingController _imeController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController;
  late TextEditingController _opisController;

  bool _isEditing = false;
  bool _isLoading = true;
  List<Oglas> _mojiOglasi = [];
  List<Recenzija> _recenzije = [];

  @override
  void initState() {
    super.initState();
    _imeController = TextEditingController();
    _emailController = TextEditingController();
    _telefonController = TextEditingController();
    _opisController = TextEditingController();
    _inicijalizirajPodatke();
  }

  @override
  void dispose() {
    _imeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _opisController.dispose();
    super.dispose();
  }

  // Dohvaćanje podataka pri pokretanju
  Future<void> _inicijalizirajPodatke() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Profil
      final profil = await supabase.from('profiles').select().eq('id', user.id).single();
      
      // 2. Izdani oglasi
      final oglasiRes = await supabase.from('oglasi').select().eq('autor_id', user.id).limit(10);
      
      // 3. Recenzije (prema tvojoj SQL shemi)
      final recenzijeRes = await supabase.from('recenzije').select('''
        *,
        ocjenjivac:profiles!recenzije_ocjenjivac_id_fkey(puno_ime),
        oglasi!recenzije_oglas_id_fkey(naslov)
      ''').eq('ocijenjeni_id', user.id).order('created_at', ascending: false);

      setState(() {
        _imeController.text = profil['puno_ime'] ?? "";
        _emailController.text = profil['email_adresa'] ?? "";
        _telefonController.text = profil['telefon'] ?? "";
        _opisController.text = profil['opis_profila'] ?? "";
        
        _mojiOglasi = (oglasiRes as List).map((json) => Oglas.fromJson(json)).toList();
        _recenzije = (recenzijeRes as List).map((json) => Recenzija.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju: $e");
      setState(() => _isLoading = false);
    }
  }

  // SPREMANJE PROMJENA
  Future<void> _spremiPromjene() async {
    final user = supabase.auth.currentUser;
    try {
      await supabase.from('profiles').update({
        'puno_ime': _imeController.text,
        'email_adresa': _emailController.text,
        'telefon': _telefonController.text,
        'opis_profila': _opisController.text,
      }).eq('id', user!.id);

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil je uspješno ažuriran!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Greška: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: darkBrown)),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(top: -50, left: -30, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 20),
                    _buildUserHeader(),
                    const SizedBox(height: 25),
                    
                    _buildEditableField("Ime i prezime:", _imeController),
                    _buildEditableField("E-mail adresa:", _emailController, enabled: false), // E-mail obično ne damo mijenjati lako
                    _buildEditableField("Broj telefona:", _telefonController),
                    _buildAboutMeField(),
                    
                    const SizedBox(height: 25),
                    _buildIzdaniPoslovi(),
                    const SizedBox(height: 25),
                    _buildRecenzijeSekcija(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios)),
        Row(
          children: [
            if (_isEditing)
              IconButton(
                onPressed: _spremiPromjene,
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              ),
            IconButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(_isEditing ? Icons.cancel : Icons.edit, color: darkBrown),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        const CircleAvatar(radius: 35, backgroundColor: Colors.white70, child: Icon(Icons.person, size: 45, color: darkBrown)),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_imeController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Row(
              children: [
                Text("4.8", style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.star, color: Colors.amber, size: 18),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: const BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          TextField(
            controller: controller,
            enabled: _isEditing && enabled,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: _isEditing && enabled ? const Icon(Icons.edit, size: 16, color: darkBrown) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: const BoxDecoration(color: cardColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
          child: const Text("Opis profila", style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
        TextField(
          controller: _opisController,
          enabled: _isEditing,
          maxLines: 4,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildIzdaniPoslovi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Izdani poslovi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          decoration: BoxDecoration(color: inputBg.withOpacity(0.5), borderRadius: BorderRadius.circular(15)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mojiOglasi.length,
            itemBuilder: (context, index) {
              final oglas = _mojiOglasi[index];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    Container(
                      height: 60, width: 60,
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.work_outline, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(oglas.naslov, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecenzijeSekcija() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recenzije", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        if (_recenzije.isEmpty)
          const Text("Nema dostupnih recenzija.", style: TextStyle(color: Colors.black45, fontSize: 13)),
        ..._recenzije.map((r) => _buildRecenzijaCard(r)).toList(),
      ],
    );
  }

  Widget _buildRecenzijaCard(Recenzija r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.ocjenjivacIme, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text("${r.ocjena}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Za posao: ${r.oglasNaslov}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
          if (r.komentar != null) ...[
            const Divider(color: Colors.white24),
            Text(r.komentar!, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ]
        ],
      ),
    );
  }
}