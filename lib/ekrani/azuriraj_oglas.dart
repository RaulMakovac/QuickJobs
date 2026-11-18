import 'package:flutter/material.dart';
import '../dekor.dart';
import '../services/oglas_service.dart';

class AzurirajOglas extends StatefulWidget {
  final Oglas oglas;
  const AzurirajOglas({super.key, required this.oglas});

  @override
  State<AzurirajOglas> createState() => _AzurirajOglasState();
}

class _AzurirajOglasState extends State<AzurirajOglas> {
  final OglasService _oglasService = OglasService();

  late TextEditingController _naslovController;
  late TextEditingController _opisController;
  late TextEditingController _isplataController;
  late TextEditingController _adresaController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _naslovController = TextEditingController(text: widget.oglas.naslov);
    _opisController = TextEditingController(text: widget.oglas.opis);
    _isplataController = TextEditingController(text: widget.oglas.isplata);
    _adresaController = TextEditingController(text: widget.oglas.adresa);
  }

  @override
  void dispose() {
    _naslovController.dispose();
    _opisController.dispose();
    _isplataController.dispose();
    _adresaController.dispose();
    super.dispose();
  }

  Future<void> _updateOglas() async {
    if (_isLoading) return;

    if (_naslovController.text.trim().isEmpty ||
        _adresaController.text.trim().isEmpty ||
        _isplataController.text.trim().isEmpty ||
        _opisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Molimo ispunite sva polja prije spremanja."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _oglasService.azurirajOglas(
        oglasId: widget.oglas.id,
        naslov: _naslovController.text,
        opis: _opisController.text,
        isplata: _isplataController.text,
        adresa: _adresaController.text,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                        onTap: _isLoading ? null : _updateOglas,
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: boje.A,
                                shape: BoxShape.circle,
                              ),
                              child: _isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(22.0),
                                      child: CircularProgressIndicator(
                                        color: boje.bg,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check_rounded,
                                      size: 45,
                                      color: boje.bg,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isLoading ? "Spremanje..." : "Spremi promjene",
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

  Widget _buildHeader(
    BuildContext context,
    QuickJobsColors boje,
    String naslovPosla,
  ) {
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