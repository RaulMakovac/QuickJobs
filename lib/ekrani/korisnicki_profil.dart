import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';
import '../dekor.dart';

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
      oglasNaslov: oglasData != null ? oglasData['naslov_oglasa'] : 'Posao',
      ocjena: json['ocjena'],
      komentar: json['komentar'],
      uloga: json['uloga_ocijenjenog'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class KorisnickiProfil extends StatefulWidget {
  final String? prikazaniKorisnikId;

  const KorisnickiProfil({super.key, this.prikazaniKorisnikId});

  @override
  State<KorisnickiProfil> createState() => _KorisnickiProfilState();
}

class _KorisnickiProfilState extends State<KorisnickiProfil> {
  final supabase = Supabase.instance.client;

  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);
  static const cardColor = Color(0xFF8F6E68);
  static const inputBg = Color(0xFFD1BDB9);

  bool get jeLiMojProfil {
    final trenutniUser = supabase.auth.currentUser;
    if (widget.prikazaniKorisnikId == null) return true;
    return trenutniUser?.id == widget.prikazaniKorisnikId;
  }

  String get ciljaniUserId => widget.prikazaniKorisnikId ?? supabase.auth.currentUser!.id;

  late TextEditingController _imeController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController;
  late TextEditingController _opisController;

  bool _isEditing = false;
  bool _isLoading = true;
  bool _prikaziSveRecenzije = false; // Kontrola skupljanja recenzija
  double _prosjecnaOcjena = 0.0;
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

  Future<void> _inicijalizirajPodatke() async {
    try {
      final profil = await supabase.from('profiles').select().eq('id', ciljaniUserId).single();
      final oglasiRes = await supabase.from('oglasi').select().eq('autor_id', ciljaniUserId).limit(10);
      final recenzijeRes = await supabase.from('recenzije').select('''
        *,
        ocjenjivac:profiles!recenzije_ocjenjivac_id_fkey(puno_ime),
        oglasi!recenzije_oglas_id_fkey(naslov_oglasa)
      ''').eq('ocijenjeni_id', ciljaniUserId).order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _imeController.text = profil['puno_ime'] ?? "";
          _emailController.text = profil['email_adresa'] ?? "";
          _telefonController.text = profil['telefon'] ?? "";
          _opisController.text = profil['opis_profila'] ?? "";
          _prosjecnaOcjena = (profil['ocjena_korisnika'] as num?)?.toDouble() ?? 0.0;
          _mojiOglasi = (oglasiRes as List).map((json) => Oglas.fromJson(json)).toList();
          _recenzije = (recenzijeRes as List).map((json) => Recenzija.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _spremiPromjene() async {
    try {
      await supabase.from('profiles').update({
        'puno_ime': _imeController.text,
        'telefon': _telefonController.text,
        'opis_profila': _opisController.text,
      }).eq('id', ciljaniUserId);
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  void _odjava() async {
    bool? potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Odjava", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        content: const Text("Jeste li sigurni da se želite odjaviti?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Odustani")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Odjavi se", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (potvrda == true) {
      await supabase.auth.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: PozadinaKrugovi(child: Center(child: CircularProgressIndicator(color: darkBrown))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SCROLLABLE NAV BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: darkBrown),
                      ),
                      if (jeLiMojProfil)
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
                            IconButton(onPressed: _odjava, icon: const Icon(Icons.logout, color: Colors.redAccent)),
                          ],
                        ),
                    ],
                  ),
                ),
                _buildUserHeader(),
                const SizedBox(height: 25),
                _buildEditableField("Ime i prezime:", _imeController),
                _buildEditableField("E-mail adresa:", _emailController, enabled: false),
                _buildEditableField("Broj telefona:", _telefonController),
                _buildAboutMeField(),
                const SizedBox(height: 25),
                _buildIzdaniPoslovi(),
                const SizedBox(height: 25),
                _buildRecenzijeSekcija(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundColor: cardColor,
          child: Icon(Icons.person, size: 45, color: Colors.white),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_imeController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text("$_prosjecnaOcjena", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool enabled = true}) {
    bool mozeEditirati = jeLiMojProfil && _isEditing && enabled;
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
            enabled: mozeEditirati,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: mozeEditirati ? const Icon(Icons.edit, size: 16, color: darkBrown) : null,
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
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: const Text("Opis profila", style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
        TextField(
          controller: _opisController,
          enabled: jeLiMojProfil && _isEditing,
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
    if (_mojiOglasi.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(jeLiMojProfil ? "Moji izdani poslovi" : "Izdani poslovi korisnika",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          height: 120,
          decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(15)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    Text(oglas.naslov, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2),
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
    if (_recenzije.isEmpty) return const SizedBox.shrink();
    final prikazane = _prikaziSveRecenzije ? _recenzije : _recenzije.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Recenzije", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Column(children: prikazane.map((r) => _buildRecenzijaCard(r)).toList()),
        ),
        if (_recenzije.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _prikaziSveRecenzije = !_prikaziSveRecenzije),
              icon: Icon(_prikaziSveRecenzije ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: darkBrown),
              label: Text(_prikaziSveRecenzije ? "Prikaži manje" : "Prikaži više (još ${_recenzije.length - 3})",
                  style: const TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
            ),
          ),
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
              Row(children: [
                Text("${r.ocjena}", style: const TextStyle(color: Colors.white)),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ]),
            ],
          ),
          Text("Za posao: ${r.oglasNaslov}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
          if (r.komentar != null) ...[const Divider(color: Colors.white24), Text(r.komentar!, style: const TextStyle(color: Colors.white, fontSize: 13))],
        ],
      ),
    );
  }
}
