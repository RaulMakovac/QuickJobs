import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart';

class ObjavaOglasa extends StatefulWidget {
  const ObjavaOglasa({super.key});

  @override
  State<ObjavaOglasa> createState() => _ObjavaOglasaState();
}

class _ObjavaOglasaState extends State<ObjavaOglasa> {
  final _naslovController = TextEditingController();
  final _adresaController = TextEditingController();
  final _isplataController = TextEditingController();
  final _opisController = TextEditingController();

  String _odabranaKategorija = "Ostalo"; //default


  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  // Glavne boje projekta
  static const bgColor = Color(0xFFE5D9D6);
  static const fieldColor = Color(0xFFD1BDB9);
  static const darkFieldColor = Color(0xFF8F6E68);

  Future<void> _objaviOglas() async {
    final naslov = _naslovController.text.trim();
    final adresa = _adresaController.text.trim();
    final isplata = _isplataController.text.trim();
    final opis = _opisController.text.trim();
    final user = supabase.auth.currentUser;

    // --- VALIDACIJA ---
    if (naslov.isEmpty || adresa.isEmpty || isplata.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Naziv, Adresa i Isplata su obavezni!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('oglasi').insert({
        'autor_id': user!.id,
        'naslov_oglasa': naslov,
        'adresa_oglasa': adresa,
        'isplata_oglasa': isplata,
        'opis_oglasa': opis,
        'kategorija': _odabranaKategorija,
        'status_oglasa': 'otvoren',
      });

      if (mounted) {
        Navigator.pop(context); // Vrati se na glavni ekran
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oglas uspješno objavljen!'),backgroundColor: Colors.green,),
          
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška pri objavi: $e'), backgroundColor: Colors.redAccent,));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: PozadinaKrugovi(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              children: [
                // Back gumb i naslov
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Objavi posao',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balans za back button
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ovdje možete objaviti oglas za koji god posao vam je potrebna pomoć!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 30),

                // Slika i Naziv (Redak)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Slika\nposla",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _customField("Naziv posla", _naslovController),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _customField("Adresa:", _adresaController),
                const SizedBox(height: 15),
                _customField("Isplata:", _isplataController, isNumber: true),
                const SizedBox(height: 15),

                // Opis (Veliko polje)
                Container(
                  height: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: darkFieldColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _opisController,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Opis posla...",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ODABIR KATEGORIJE (Ispod detalja/opisa oglasa)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _odabranaKategorija,
                    dropdownColor: fieldColor,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black54,
                    ),

                    // Prolazimo kroz ključeve mape kako bismo izgradili stavke s ikonama
                    items: kategorijeSaIkonama.keys.map((String kategorija) {
                      return DropdownMenuItem<String>(
                        value: kategorija,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kategorijeSaIkonama[kategorija],
                              color: const Color(
                                0xFF4A2C29,
                              ), // Tvoja standardna tamnosmeđa boja
                              size: 22,
                            ),
                            const SizedBox(
                              width: 12,
                            ), // Razmak između ikonice i teksta
                            Text(kategorija),
                          ],
                        ),
                      );
                    }).toList(),

                    onChanged: (novo) {
                      setState(() {
                        _odabranaKategorija = novo!;
                      });
                    },
                  ),
                ),

                // Smanjen razmak kako layout ne bi pobjegao prenisko
                const SizedBox(height: 40),

                // Gumb za objavu (Kvačica)
                GestureDetector(
                  onTap: _isLoading ? null : _objaviOglas,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: darkFieldColor,
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            size: 50,
                            color: Colors.black,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customField(
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }
}
