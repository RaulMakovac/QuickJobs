import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart'; 
import '/ekrani/glavni_ekran.dart';

class AzurirajOglas extends StatefulWidget {
  final Oglas oglas;
  const AzurirajOglas({super.key, required this.oglas});

  @override
  State<AzurirajOglas> createState() => _AzurirajOglasState();
}

class _AzurirajOglasState extends State<AzurirajOglas> {
  final supabase = Supabase.instance.client;

  late TextEditingController _naslovController;
  late TextEditingController _opisController;
  late TextEditingController _isplataController;
  late TextEditingController _adresaController;

  @override
  void initState() {
    super.initState();
    _naslovController = TextEditingController(text: widget.oglas.naslov);
    _opisController = TextEditingController(text: widget.oglas.opis);
    _isplataController = TextEditingController(text: widget.oglas.isplata);
    _adresaController = TextEditingController(text: widget.oglas.adresa);
  }

  Future<void> _updateOglas() async {
    try {
      await supabase
          .from('oglasi')
          .update({
            'naslov_oglasa': _naslovController.text,
            'opis_oglasa': _opisController.text,
            'isplata_oglasa': _isplataController.text,
            'adresa_oglasa': _adresaController.text,
          })
          .eq('id', widget.oglas.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oglas uspješno ažuriran!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Greška: $e"), backgroundColor: Colors.red),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        // Koristimo tvoju custom pozadinu
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                context,
                tamnoSmedja,
                widget.oglas.naslov,
              ), // Dinamički naslov
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // STAKLENI KONTEJNER OKO FORME
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            _buildInputField(
                              "Naslov posla",
                              _naslovController,
                              Icons.work_outline,
                              tamnoSmedja,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Lokacija / Adresa",
                              _adresaController,
                              Icons.location_on_outlined,
                              tamnoSmedja,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Isplata (€)",
                              _isplataController,
                              Icons.euro_symbol_rounded,
                              tamnoSmedja,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Detaljan opis",
                              _opisController,
                              Icons.notes_rounded,
                              tamnoSmedja,
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // GUMB ZA SPREMANJE PROMJENA
                      GestureDetector(
                        onTap: _updateOglas,
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: tamnoSmedja,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: tamnoSmedja.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 45,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Spremi promjene",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tamnoSmedja,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color boja, String naslovPosla) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  "Uredi oglas",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '"$naslovPosla"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow
                      .ellipsis, // Ako je naslov predug, stavit će tri točkice
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: boja,
                    fontStyle: FontStyle
                        .italic, // Navodnici izgledaju bolje u italic verziji IMHO
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String labela,
    TextEditingController controller,
    IconData icon,
    Color boja, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABELA IZNAD POLJA
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            labela,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: boja.withOpacity(0.8),
            ),
          ),
        ),
        // POLJE ZA UNOS
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          decoration: InputDecoration(
            // Ikona je sada fiksirana u vrhu čak i kod opisa (maxLines > 1)
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
              child: Icon(icon, color: boja, size: 22),
            ),
            filled: true,
            fillColor: const Color(0xFFD1BDB9).withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}
