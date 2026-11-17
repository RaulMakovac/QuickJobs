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
  String _tekstOcjene = ""; 
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
        oglasi!recenzije_oglas_id_fkey(naslov_oglasa, kategorija)
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

  void _odjava(QuickJobsColors boje) async {
    bool? potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: boje.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Odjava",
          style: TextStyle(color: boje.A, fontWeight: FontWeight.bold),
        ),
        content: Text("Jeste li sigurni da se želite odjaviti?", style: TextStyle(color: boje.A)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Odustani", style: TextStyle(color: boje.A)),
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

  @override
  Widget build(BuildContext context) {
    // Dohvaćamo definirane boje iz dekor.dart
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: boje.bg,
        body: PozadinaKrugovi(
          krugBoja: boje.C,
          child: Center(child: CircularProgressIndicator(color: boje.A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
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
                                icon: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: boje.A,
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
                                        color: boje.A,
                                        size: 26,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _odjava(boje),
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
                                              boje,
                                            ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                            ],
                          ),
                        ),

                        _buildUserHeader(boje),
                        const SizedBox(height: 25),
                        _buildEditableField(
                          "Ime i prezime:",
                          _imeController,
                          Icons.person_outline_rounded,
                          boje,
                        ),
                        _buildEditableField(
                          "E-mail adresa:",
                          _emailController,
                          Icons.mail_outline_rounded,
                          boje,
                          enabled: false,
                        ),
                        _buildEditableField(
                          "Broj telefona:",
                          _telefonController,
                          Icons.phone_android_rounded,
                          boje,
                        ),
                        _buildAboutMeField(boje),

                        // --- IZDANI POSLOVI ---
                        if (_mojiOglasi.isNotEmpty) ...[
                          const SizedBox(height: 25),
                          _buildIzdaniPoslovi(boje),
                        ],

                        // --- RECENZIJE ---
                        const SizedBox(height: 25),
                        _buildRecenzijeSekcija(boje),

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

  Widget _buildUserHeader(QuickJobsColors boje) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: boje.C,
          child: Icon(Icons.person, size: 45, color: boje.A),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _imeController.text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
            const SizedBox(height: 4),
            _prosjecnaOcjena > 0
                ? Row(
                    children: [
                      Text(
                        _prosjecnaOcjena.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: boje.A,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    ],
                  )
                : Text(
                    "Nema ocjena",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: boje.A?.withValues(alpha: 0.6),
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
    IconData ikona,
    QuickJobsColors boje, {
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
            decoration: BoxDecoration(
              color: boje.B, // Mali pravokutnik koristi boju C
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ikona,
                  color: boje.A,
                  size: 14,
                ), 
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: boje.A,
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: boje.A,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: boje.C,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                borderSide: BorderSide.none,
              ),
              suffixIcon: mozeEditirati
                  ? Icon(Icons.edit, size: 16, color: boje.A)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeField(QuickJobsColors boje) {
    bool mozeEditirati = jeLiMojProfil && _isEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: boje.B, // Mali pravokutnik koristi boju C
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description_outlined, color: boje.A, size: 14),
                const SizedBox(width: 6),
                Text(
                  "Opis profila",
                  style: TextStyle(
                    color: boje.A,
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
            style: TextStyle(
              fontSize: 13,
              color: boje.A,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: boje.C,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                borderSide: BorderSide.none,
              ),
              suffixIcon: mozeEditirati
                  ? Icon(Icons.edit, size: 16, color: boje.A)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIzdaniPoslovi(QuickJobsColors boje) {
    if (_mojiOglasi.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          jeLiMojProfil ? "Moji izdani poslovi" : "Izdani poslovi korisnika",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: boje.A,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 125,
          decoration: BoxDecoration(
            color: boje.C,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: _mojiOglasi.length,
            itemBuilder: (context, index) {
              final oglas = _mojiOglasi[index];
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
                        color: boje.bg?.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        ikonaOglasa,
                        color: boje.A,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      oglas.naslov,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: boje.A,
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

  Widget _buildRecenzijeSekcija(QuickJobsColors boje) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recenzije",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: boje.A,
          ),
        ),
        const SizedBox(height: 10),
        _recenzije.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: boje.B,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "Korisnik još nije recenziran.",
                  style: TextStyle(
                    color: boje.A?.withValues(alpha: 1.0),
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: (_prikaziSveRecenzije
                              ? _recenzije
                              : _recenzije.take(3).toList())
                          .map((r) => _buildRecenzijaCard(r, boje))
                          .toList(),
                    ),
                  ),
                  if (_recenzije.length > 3)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(
                            () => _prikaziSveRecenzije = !_prikaziSveRecenzije),
                        icon: Icon(
                          _prikaziSveRecenzije
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: boje.A,
                        ),
                        label: Text(
                          _prikaziSveRecenzije
                              ? "Prikaži manje"
                              : "Prikaži više (još ${_recenzije.length - 3})",
                          style: TextStyle(
                            color: boje.A,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildRecenzijaCard(Recenzija r, QuickJobsColors boje) {
    final ikonaPosla =
        kategorijeSaIkonama[r.oglasKategorija] ?? Icons.work_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: boje.C,
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
                style: TextStyle(
                  color: boje.A,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    "${r.ocjena}",
                    style: TextStyle(
                      color: boje.A,
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
          Row(
            children: [
              Icon(ikonaPosla, color: boje.A?.withValues(alpha: 0.7), size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Za posao: ${r.oglasNaslov}",
                  style: TextStyle(
                    color: boje.A?.withValues(alpha: 0.8),
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
            Divider(color: boje.A?.withValues(alpha: 0.2), height: 15),
            Text(
              r.komentar!,
              style: TextStyle(color: boje.A, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  void _prikaziDijalogZaReportProfila(BuildContext context, String korisnikId, QuickJobsColors boje) {
    String privremeniRazlog = "Scam / Neisplata";
    final komentarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: boje.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: Colors.red),
              const SizedBox(width: 10),
              Text(
                "Prijavi korisnika",
                style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Odaberite razlog zašto prijavljujete ovog korisnika nakon obavljenog posla:",
                style: TextStyle(color: boje.A),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: privremeniRazlog,
                dropdownColor: boje.C,
                style: TextStyle(color: boje.A, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: boje.C,
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
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: boje.A))))
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
                style: TextStyle(color: boje.A),
                decoration: InputDecoration(
                  hintText: "Opišite detaljnije što se dogodilo...",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: boje.C,
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
              child: Text("Odustani", style: TextStyle(color: boje.A)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: boje.A,
                foregroundColor: boje.bg,
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
              child: const Text("Pošalji"),
            ),
          ],
        ),
      ),
    );
  }
}