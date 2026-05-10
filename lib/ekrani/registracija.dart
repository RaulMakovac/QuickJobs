import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Ključno za klik na tekst
import 'package:supabase_flutter/supabase_flutter.dart';
import 'opciUvjeti.dart'; // Provjeri putanju do ekrana s uvjetima

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
  bool _omoguciGps = false;
  bool _isLoading = false;

  // Boje usklađene s dizajnom
  static const backgroundColor = Color(0xFFE5D9D6);
  static const circleColor = Color(0xFFD6C8C5);
  static const inputFieldColor = Color(0xFFD1BDB9);
  static const darkBrownColor = Color(0xFF6D3F3A); 
  static const mediumBrownColor = Color(0xFF8F6E68);
  static const textColor = Color(0xFF2E2E2E);
  static const hintTextColor = Color(0xFF8C5353);

  Future<void> _signUp() async {
    if (_imeController.text.isEmpty || _emailController.text.isEmpty || 
        _lozinkaController.text.isEmpty || _telefonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva obavezna polja'))
      );
      return;
    }
    if (!_prihvacamUvjete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morate prihvatiti uvjete korištenja'))
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
          SnackBar(content: Text(error.message), backgroundColor: Colors.red)
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dogodila se neočekivana greška'), backgroundColor: Colors.red)
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Dekorativni krugovi
          Positioned(
            top: -120, left: -100,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: CirclePainter(color: circleColor),
            ),
          ),
          Positioned(
            bottom: -80, right: -50,
            child: CustomPaint(
              size: const Size(300, 300),
              painter: CirclePainter(color: circleColor),
            ),
          ),

          SafeArea(
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
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'Registracija',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36, 
                        fontWeight: FontWeight.bold, 
                        color: darkBrownColor, 
                        letterSpacing: 1.2
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Molimo vas da unesete vaše korisničke podatke',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),

                    const SizedBox(height: 40),

                    _buildInputField(_imeController, 'Ime i prezime', Icons.person),
                    const SizedBox(height: 16),
                    _buildInputField(_emailController, 'E-mail adresa', Icons.email, isEmail: true),
                    const SizedBox(height: 16),
                    _buildInputField(_telefonController, 'Broj telefona', Icons.phone, isPhone: true),
                    const SizedBox(height: 16),
                    _buildInputField(_lozinkaController, 'Lozinka', Icons.lock, isPassword: true),

                    const SizedBox(height: 24),

                    // CHECKBOX S LINKOM NA UVJETE
                    _buildCheckbox('', _prihvacamUvjete, (value) {
                      setState(() => _prihvacamUvjete = value!);
                    }, isLegal: true),

                    // OBIČAN CHECKBOX ZA GPS
                    _buildCheckbox('Omogući korištenje GPS usluga', _omoguciGps, (value) {
                      setState(() => _omoguciGps = value!);
                    }),

                    const SizedBox(height: 40),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: darkBrownColor))
                        : _buildMainButton('Registracija', darkBrownColor, _signUp),
                          
                    const SizedBox(height: 16),
                    
                    _buildMainButton(
                      'Log in', 
                      mediumBrownColor, 
                      () => Navigator.pushNamed(context, '/ekrani/login'),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Već imate profil?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false, bool isEmail = false, bool isPhone = false}) {
    return Container(
      decoration: BoxDecoration(color: inputFieldColor, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
        style: const TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: hintTextColor, fontSize: 16),
          prefixIcon: Icon(icon, color: hintTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  // MODIFICIRANI CHECKBOX S PODRŠKOM ZA KLIKABILNI TEKST
  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged, {bool isLegal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: value, 
            onChanged: onChanged, 
            activeColor: darkBrownColor, 
            checkColor: Colors.white
          ),
          Expanded(
            child: isLegal 
              ? RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: textColor, fontFamily: 'Sans Serif'),
                    children: [
                      const TextSpan(text: 'Prihvaćam '),
                      TextSpan(
                        text: 'uvjete korištenja',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: darkBrownColor,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UvjetiKoristenjaEkran()),
                            );
                          },
                      ),
                      const TextSpan(text: ' aplikacije'),
                    ],
                  ),
                )
              : Text(title, style: const TextStyle(fontSize: 14, color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        shadowColor: Colors.black45,
      ),
      child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

// Painter za krugove u pozadini
class CirclePainter extends CustomPainter {
  final Color color;
  CirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}