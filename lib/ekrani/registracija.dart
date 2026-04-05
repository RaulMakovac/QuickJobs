import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// DEFINICIJA SUPABASE KLIJENTA
final supabase = Supabase.instance.client;

class registracija extends StatefulWidget {
  const registracija({super.key});

  @override
  State<registracija> createState() => _registracijaState();
}

class _registracijaState extends State<registracija> {
  final _imeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _lozinkaController = TextEditingController();
  
  bool _prihvacamUvjete = false;
  bool _omoguciGps = false;
  bool _isLoading = false;

  // Boje
  static const backgroundColor = Color(0xFFE5D9D6);
  static const circleColor = Color(0xFFD6C8C5);
  static const inputFieldColor = Color(0xFFD1BDB9);
  static const darkBrownColor = Color(0xFF6D3F3A); 
  static const mediumBrownColor = Color(0xFF8F6E68);
  static const textColor = Color(0xFF2E2E2E);
  static const hintTextColor = Color(0xFF8C5353);

  // Funkcija za registraciju s navigacijom nakon uspjeha
  Future<void> _signUp() async {
    if (_imeController.text.isEmpty || _emailController.text.isEmpty || _lozinkaController.text.isEmpty || _telefonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Molimo popunite sva obavezna polja')));
      return;
    }
    if (!_prihvacamUvjete) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Morate prihvatiti uvjete korištenja')));
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

        // NAKON USPJEHA: Vodi na Odabir ekran i briše povijest (pushReplacement)
        Navigator.pushReplacementNamed(context, '/ekrani/odabir');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.red));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dogodila se neočekivana greška'), backgroundColor: Colors.red));
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
          Positioned(
            top: -120,
            left: -100,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: CirclePainter(color: circleColor),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -50,
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

                    const SizedBox(height: 64),

                    const Text(
                      'Registracija',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: darkBrownColor, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Molimo vas da unesete vaše korisničke podatke',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),

                    const SizedBox(height: 48),

                    _buildInputField(_imeController, 'Ime i prezime', Icons.person),
                    const SizedBox(height: 16),
                    _buildInputField(_emailController, 'E-mail adresa', Icons.email, isEmail: true),
                    const SizedBox(height: 16),
                    _buildInputField(_telefonController, 'Broj telefona', Icons.phone, isPhone: true),
                    const SizedBox(height: 16),
                    _buildInputField(_lozinkaController, 'Lozinka', Icons.lock, isPassword: true),

                    const SizedBox(height: 24),

                    _buildCheckbox('Prihvaćam uvjete korištenja aplikacije', _prihvacamUvjete, (value) {
                      setState(() => _prihvacamUvjete = value!);
                    }),
                    _buildCheckbox('Omogući korištenje GPS usluga', _omoguciGps, (value) {
                      setState(() => _omoguciGps = value!);
                    }),

                    const SizedBox(height: 48),

                    // --- SREĐENI GUMBI ---
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: darkBrownColor))
                        : _buildMainButton(
                            'Registracija', 
                            darkBrownColor, // Glavna akcija je tamnija
                            _signUp,        // Pokreće registraciju
                          ),
                          
                    const SizedBox(height: 16),
                    
                    _buildMainButton(
                      'Log in', 
                      mediumBrownColor, // Pomoćna akcija je svjetlija
                      () {
                        Navigator.pushNamed(context, '/ekrani/login');
                      },
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

  Widget _buildCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged, activeColor: darkBrownColor, checkColor: Colors.white),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: textColor))),
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