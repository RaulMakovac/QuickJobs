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
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, boje, widget.oglas.naslov),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: boje.C,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              "Naslov posla",
                              _naslovController,
                              Icons.work_outline,
                              boje,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Lokacija / Adresa",
                              _adresaController,
                              Icons.location_on_outlined,
                              boje,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Isplata (€)",
                              _isplataController,
                              Icons.euro_symbol_rounded,
                              boje,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            _buildInputField(
                              "Detaljan opis",
                              _opisController,
                              Icons.notes_rounded,
                              boje,
                              maxLines: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _updateOglas,
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: boje.A,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 45,
                                color: boje.bg,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Spremi promjene",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: boje.A,
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

  Widget _buildHeader(BuildContext context, QuickJobsColors boje, String naslovPosla) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: boje.A),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "Uredi oglas",
                  style: TextStyle(
                    fontSize: 14,
                    color: boje.A?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '"$naslovPosla"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: boje.A,
                    fontStyle: FontStyle.italic,
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
    QuickJobsColors boje, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            labela,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: boje.A?.withValues(alpha: 0.8),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 16, color: boje.A),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 80 : 0),
              child: Icon(icon, color: boje.A, size: 22),
            ),
            filled: true,
            fillColor: boje.bg?.withValues(alpha: 0.7),
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