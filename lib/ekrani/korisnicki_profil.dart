import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart';
import '../dekor.dart';

// --- MODEL ZA RECENZIJU ---
class Recenzija {
  final String id;
  final String ocjenjivacIme;
  final String oglasNaslov;
  final String? oglasKategorija;
  final int ocjena;
  final String? komentar;
  final String uloga;
  final DateTime createdAt;

  Recenzija({
    required this.id,
    required this.ocjenjivacIme,
    required this.oglasNaslov,
    required this.oglasKategorija,
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
      ocjenjivacIme: ocjenjivacData != null
          ? ocjenjivacData['puno_ime']
          : 'Korisnik',
      oglasNaslov: oglasData != null ? oglasData['naslov_oglasa'] : 'Posao',
      ocjena: json['ocjena'],
      komentar: json['komentar'],
      uloga: json['uloga_ocijenjenog'],
      createdAt: DateTime.parse(json['created_at']),
      oglasKategorija: oglasData != null
          ? (oglasData['kategorija'] ?? 'Ostalo')
          : 'Ostalo',
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

  String get ciljaniUserId =>
      widget.prikazaniKorisnikId ?? supabase.auth.currentUser!.id;

  late TextEditingController _imeController;
  late TextEditingController _emailController;
  late TextEditingController _telefonController;
  late TextEditingController _opisController;

  bool _isEditing = false;
  bool _isLoading = true;
  bool _prikaziSveRecenzije = false;
  double _prosjecnaOcjena = 0.0;
  String _tekstOcjene = ""; //ne znam zašto piše da se ne koristi doslovno se koristi u buildu al whatever
  List<Oglas> _mojiOglasi = [];
  List<Recenzija> _recenzije = [];

  Future<bool> _provjeriSmijeLiReportati(String prikazaniKorisnikId) async {
    final user = supabase.auth.currentUser;
    if (user == null || user.id == prikazaniKorisnikId) return false;

    try {
      final response = await supabase
          .from('oglasi')
          .select('id')
          .or('status_oglasa.eq.završen,status_oglasa.eq.obavljen')
          .or(
            'and(autor_id.eq.${user.id},obavljac_id.eq.$prikazaniKorisnikId),and(autor_id.eq.$prikazaniKorisnikId,obavljac_id.eq.${user.id})',
          );

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint("Greška pri provjeri suradnje: $e");
      return false;
    }
  }

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
      final profil = await supabase
          .from('profiles')
          .select()
          .eq('id', ciljaniUserId)
          .single();
      final oglasiRes = await supabase
          .from('oglasi')
          .select()
          .eq('autor_id', ciljaniUserId)
          .limit(10);
      final recenzijeRes = await supabase
          .from('recenzije')
          .select('''
        *,
        ocjenjivac:profiles!recenzije_ocjenjivac_id_fkey(puno_ime),
        oglasi!recenzije_oglas_id_fkey(naslov_oglasa, kategorija) -- Povlačimo i kategoriju za ikonu
      ''')
          .eq('ocijenjeni_id', ciljaniUserId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _imeController.text = profil['puno_ime'] ?? "";
          _emailController.text = profil['email_adresa'] ?? "";
          _telefonController.text = profil['telefon'] ?? "";
          _opisController.text = profil['opis_profila'] ?? "";
          final ocjenaIzBaze = (profil['ocjena_korisnika'] as num?)?.toDouble();

          if (ocjenaIzBaze == null || ocjenaIzBaze == 0.0) {
            _prosjecnaOcjena = 0.0;
            _tekstOcjene = "Korisnik još nije ocjenjen";
          } else {
            _prosjecnaOcjena = ocjenaIzBaze;
            _tekstOcjene =
                "Prosječna ocjena: ${_prosjecnaOcjena.toStringAsFixed(1)}";
          }
          _mojiOglasi = (oglasiRes as List)
              .map((json) => Oglas.fromJson(json))
              .toList();
          _recenzije = (recenzijeRes as List)
              .map((json) => Recenzija.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _spremiPromjene() async {
    try {
      await supabase
          .from('profiles')
          .update({
            'puno_ime': _imeController.text,
            'telefon': _telefonController.text,
            'opis_profila': _opisController.text,
          })
          .eq('id', ciljaniUserId);
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  void _odjava() async {
    bool? potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Odjava",
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
        ),
        content: const Text("Jeste li sigurni da se želite odjaviti?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              "Odjavi se",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (potvrda == true) {
      await supabase.auth.signOut();
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
//dok se loada je prazno
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: PozadinaKrugovi(
          child: Center(child: CircularProgressIndicator(color: darkBrown)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- NAV BAR ---
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: darkBrown,
                                  size: 26,
                                ),
                              ),
                              if (jeLiMojProfil)
                                Row(
                                  children: [
                                    if (_isEditing)
                                      IconButton(
                                        onPressed: _spremiPromjene,
                                        icon: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 28,
                                        ),
                                      ),
                                    IconButton(
                                      onPressed: () => setState(
                                        () => _isEditing = !_isEditing,
                                      ),
                                      icon: Icon(
                                        _isEditing
                                            ? Icons.cancel_rounded
                                            : Icons.edit_rounded,
                                        color: darkBrown,
                                        size: 26,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _odjava,
                                      icon: const Icon(
                                        Icons.logout_rounded,
                                        color: Colors.redAccent,
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                FutureBuilder<bool>(
                                  future: _provjeriSmijeLiReportati(
                                    ciljaniUserId,
                                  ),
                                  builder: (context, snapshot) {
                                    if (snapshot.data == true) {
                                      return IconButton(
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          color: Colors.redAccent,
                                          size: 30,
                                        ),
                                        tooltip: "Reportaj korisnika",
                                        onPressed: () =>
                                            _prikaziDijalogZaReportProfila(
                                              context,
                                              ciljaniUserId,
                                            ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                            ],
                          ),
                        ),

                        _buildUserHeader(),
                        const SizedBox(height: 25),
                        _buildEditableField(
                          "Ime i prezime:",
                          _imeController,
                          Icons.person_outline_rounded,
                        ),
                        _buildEditableField(
                          "E-mail adresa:",
                          _emailController,
                          Icons.mail_outline_rounded,
                          enabled: false,
                        ),
                        _buildEditableField(
                          "Broj telefona:",
                          _telefonController,
                          Icons.phone_android_rounded,
                        ),
                        _buildAboutMeField(),

                        // --- IZDANI POSLOVI ---
                        if (_mojiOglasi.isNotEmpty) ...[
                          const SizedBox(height: 25),
                          _buildIzdaniPoslovi(),
                        ],

                        // --- RECENZIJE ---
                        if (_recenzije.isNotEmpty) ...[
                          const SizedBox(height: 25),
                          _buildRecenzijeSekcija(),
                        ],

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
          Text(
            _imeController.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 4),
          _prosjecnaOcjena > 0 
            ? Row(
                children: [
                  Text(
                    _prosjecnaOcjena.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                ],
              )
            : const Text(
                "Nema ocjena",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black54,
                  
                ),
              ),
        ],
      ),
    ],
  );
}

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData ikona, {
    bool enabled = true,
  }) {
    bool mozeEditirati = jeLiMojProfil && _isEditing && enabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ikona,
                  color: Colors.white,
                  size: 14,
                ), 
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            enabled: mozeEditirati,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkBrown,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: mozeEditirati
                  ? const Icon(Icons.edit, size: 16, color: darkBrown)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeField() {
    bool mozeEditirati = jeLiMojProfil && _isEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Opis profila",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _opisController,
            enabled: mozeEditirati,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 13,
              color: darkBrown,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                borderSide: BorderSide.none,
              ),
              suffixIcon: mozeEditirati
                  ? const Icon(Icons.edit, size: 16, color: darkBrown)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIzdaniPoslovi() {
    if (_mojiOglasi.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jeLiMojProfil ? "Moji izdani poslovi" : "Izdani poslovi korisnika",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkBrown,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 125,
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: _mojiOglasi.length,
            itemBuilder: (context, index) {
              final oglas = _mojiOglasi[index];
              // POPRAVAK kategorije se prikazuju kao ikone umjesto generičke ikone posla
              final ikonaOglasa =
                  kategorijeSaIkonama[oglas.kategorija] ?? Icons.work_outline;

              return Container(
                width: 95,
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        ikonaOglasa,
                        color: Colors.white,
                        size: 24,
                      ), // Pravilna ikona posla
                    ),
                    const SizedBox(height: 6),
                    Text(
                      oglas.naslov,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    final prikazane = _prikaziSveRecenzije
        ? _recenzije
        : _recenzije.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recenzije",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkBrown,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: prikazane.map((r) => _buildRecenzijaCard(r)).toList(),
          ),
        ),
        if (_recenzije.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _prikaziSveRecenzije = !_prikaziSveRecenzije),
              icon: Icon(
                _prikaziSveRecenzije
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: darkBrown,
              ),
              label: Text(
                _prikaziSveRecenzije
                    ? "Prikaži manje"
                    : "Prikaži više (još ${_recenzije.length - 3})",
                style: const TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecenzijaCard(Recenzija r) {
    final ikonaPosla =
        kategorijeSaIkonama[r.oglasKategorija] ?? Icons.work_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.ocjenjivacIme,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    "${r.ocjena}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Dodana ikonica tick uz naziv posla unutar recenzije
          Row(
            children: [
              Icon(ikonaPosla, color: Colors.white60, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Za posao: ${r.oglasNaslov}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (r.komentar != null && r.komentar!.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 15),
            Text(
              r.komentar!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _prikaziDijalogZaReportProfila(BuildContext context, String korisnikId) {
    String privremeniRazlog = "Scam / Neisplata";
    final komentarController = TextEditingController();
//gumb za prijavu AKO su korisnici surađivali na obavljenom poslu onda se može reportati, inače ne, to provjeravamo u appbaru i ako se može reportati onda se prikaže ikona zastavice koja otvara ovaj dijalog
//good grief take it to a publisher :skull:
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Prijavi korisnika",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Odaberite razlog zašto prijavljujete ovog korisnika nakon obavljenog posla:",
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: privremeniRazlog,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    [
                          "Scam / Neisplata",
                          "Lažno izvršen posao",
                          "Neprimjereno ponašanje",
                          "Ostalo",
                        ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      privremeniRazlog = v;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: komentarController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Opišite detaljnije što se dogodilo...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                komentarController.dispose();
                Navigator.pop(context);
              },
              child: const Text("Odustani"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A2C29),
              ),
              onPressed: () async {
                final user = supabase.auth.currentUser;
                if (user == null) return;

                try {
                  await supabase.from('reports').insert({
                    'prijavitelj_id': user.id,
                    'oglas_id': null,
                    'prijavljeni_korisnik_id': korisnikId,
                    'razlog': privremeniRazlog,
                    'komentar': komentarController.text,
                  });

                  komentarController.dispose();

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Korisnik reportan. Hvala na povratnoj informaciji!",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Greška pri slanju reporta na profil: $e");
                }
              },
              child: const Text(
                "Pošalji",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
