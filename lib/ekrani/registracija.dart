import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Ključno za klik na tekst
import 'package:supabase_flutter/supabase_flutter.dart';
import 'opciUvjeti.dart'; // Provjeri putanju do ekrana s uvjetima
import '../dekor.dart'; // Uvoz centraliziranih boja i teme

// DEFINICIJA SUPABASE KLIJENTA
final supabase = Supabase.instance.client;

class RegistracijaEkran extends StatefulWidget {
  const RegistracijaEkran({super.key});

  @override
  State<RegistracijaEkran> createState() => _RegistracijaEkranState();
}

class _RegistracijaEkranState extends State<RegistracijaEkran> {
  final _imeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _lozinkaController = TextEditingController();

  bool _prihvacamUvjete = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_imeController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _lozinkaController.text.isEmpty ||
        _telefonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva obavezna polja')),
      );
      return;
    }
    if (!_prihvacamUvjete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morate prihvatiti uvjete korištenja')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _lozinkaController.text.trim(),
        data: {
          'puno_ime': _imeController.text.trim(),
          'telefon': _telefonController.text.trim(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uspjeh! Molimo prijavite se.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/ekrani/odabir');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dogodila se neočekivana greška'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _imeController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _lozinkaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dohvaćamo definirane boje iz dekor.dart
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back gumb
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 26,
                          color: boje.A,
                        ),
                      ),
                    ),
                  ),

                  Text(
                    'Registracija',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: boje.A,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Molimo vas da unesete vaše korisničke podatke',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: boje.A),
                  ),

                  const SizedBox(height: 40),

                  _buildInputField(
                    _imeController,
                    'Ime i prezime',
                    Icons.person,
                    boje,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _emailController,
                    'E-mail adresa',
                    Icons.email,
                    boje,
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _telefonController,
                    'Broj telefona',
                    Icons.phone,
                    boje,
                    isPhone: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _lozinkaController,
                    'Lozinka',
                    Icons.lock,
                    boje,
                    isPassword: true,
                  ),

                  const SizedBox(height: 24),

                  // CHECKBOX S LINKOM NA UVJETE
                  _buildCheckbox('', _prihvacamUvjete, (value) {
                    setState(() => _prihvacamUvjete = value!);
                  }, boje, isLegal: true),

                  const SizedBox(height: 40),

                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: boje.A,
                          ),
                        )
                      : _buildMainButton(
                          'Registracija',
                          boje.A!,
                          boje.bg!,
                          _signUp,
                        ),

                  const SizedBox(height: 16),

                  _buildMainButton(
                    'Log in',
                    boje.B!,
                    boje.A!,
                    () => Navigator.pushNamed(context, '/ekrani/login'),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Već imate profil?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: boje.A,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    IconData icon,
    QuickJobsColors boje, {
    bool isPassword = false,
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isPhone ? TextInputType.phone : TextInputType.text),
        style: TextStyle(color: boje.A, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: boje.A?.withValues(alpha: 0.65),
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: boje.A?.withValues(alpha: 0.75)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // MODIFICIRANI CHECKBOX S PODRŠKOM ZA KLIKABILNI TEKST UVJETA
  Widget _buildCheckbox(
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
    QuickJobsColors boje, {
    bool isLegal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Theme(
          data: ThemeData(
            unselectedWidgetColor: boje.A, // Boja okvira kada NIJE označen
          ),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: boje.A,
            checkColor: boje.bg,
            side: BorderSide(
              color: boje.A!,         // Precizna definicija ruba kućice
              width: 2.0,
          ),
          ),
        ),
          Expanded(
            child: isLegal
                ? RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: boje.A,
                        fontFamily: 'Sans Serif',
                      ),
                      children: [
                        const TextSpan(text: 'Prihvaćam '),
                        TextSpan(
                          text: 'uvjete korištenja',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: boje.A,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const UvjetiKoristenjaEkran(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(text: ' aplikacije'),
                      ],
                    ),
                  )
                : Text(
                    title,
                    style: TextStyle(fontSize: 14, color: boje.A),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(
    String text,
    Color bgColor,
    Color fgColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        shadowColor: Colors.black45,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
