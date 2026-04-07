import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/ekrani/glavni_ekran.dart'; 

class AzurirajOglas extends StatefulWidget {
  final Oglas oglas;
  const AzurirajOglas({super.key, required this.oglas});

  @override
  State<AzurirajOglas> createState() => _AzurirajOglasState();
}

class _AzurirajOglasState extends State<AzurirajOglas> {
  final supabase = Supabase.instance.client;
  
  // Kontroleri s već upisanim podacima iz posta
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
      await supabase.from('oglasi').update({
        'naslov': _naslovController.text,
        'opis': _opisController.text,
        'isplata': _isplataController.text,
        'adresa': _adresaController.text,
      }).eq('id', widget.oglas.id);

      if (mounted) {
        Navigator.pop(context, true); // Vraća 'true' kao znak da je update uspio
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Greška: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6), // Tvoja standardna pozadina
      appBar: AppBar(title: const Text("Uredi oglas"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildTextField(_naslovController, "Naslov posla"),
            const SizedBox(height: 15),
            _buildTextField(_adresaController, "Adresa"),
            const SizedBox(height: 15),
            _buildTextField(_isplataController, "Isplata (€)", keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(_opisController, "Opis", maxLines: 5),
            const SizedBox(height: 30),
            
            // Gumb s kvačicom za spasiti (kao na tvojoj skici)
            GestureDetector(
              onTap: _updateOglas,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFF8F6E68), shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 40, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFD1BDB9), // Boja iz tvog search bara
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}