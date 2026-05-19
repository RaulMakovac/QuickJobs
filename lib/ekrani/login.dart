import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// DEFINICIJA SUPABASE KLIJENTA
final supabase = Supabase.instance.client;

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _LoginState();
}

class _LoginState extends State<login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordObscured = true; // DODANO: Stanje za sakrivanje/prikaz lozinke

  // Boje usklađene s Registracijom
  static const backgroundColor = Color(0xFFE5D9D6);
  static const circleColor = Color(0xFFD6C8C5);
  static const inputFieldColor = Color(0xFFD1BDB9);
  static const darkBrownColor = Color(0xFF6D3F3A);
  static const textColor = Color(0xFF2E2E2E);
  static const hintTextColor = Color(0xFF8C5353);

  // Funkcija za login na Supabase
  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite email i lozinku')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
  await supabase.auth.signInWithPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );

  if (mounted) {
    Navigator.pushReplacementNamed(context, '/ekrani/glavni_ekran');
  }
} on AuthApiException catch (error) {
  // Specifično hvatanje API grešaka (poput "Invalid login credentials")
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message), 
        backgroundColor: Colors.red,
      ),
    );
  }
} on AuthException catch (error) {
  // Ostale općenite Supabase auth greške
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message), 
        backgroundColor: Colors.red,
      ),
    );
  }
} catch (error) {
  // Sve ostalo van okvira authentifikacije
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // POZADINSKI KRUGOVI
          Positioned(
            top: -100,
            right: -80,
            child: CustomPaint(
              size: const Size(250, 250),
              painter: CirclePainter(color: circleColor),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: CirclePainter(color: circleColor),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gumb natrag
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 26,
                          color: Color(0xFF4A2C29),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // NASLOV
                  const Text(
                    'Dobrodošli natrag',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: darkBrownColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prijavite se u svoj QuickJobs račun',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),

                  const SizedBox(height: 48),

                  // INPUT POLJA
                  _buildInputField(
                    _emailController,
                    'E-mail adresa',
                    Icons.email,
                    isEmail: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _passwordController,
                    'Lozinka',
                    Icons.lock,
                    isPassword: true,
                  ),

                  const SizedBox(height: 12),

                  // Zaboravljena lozinka
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, // Ovdje ide reset lozinke kasnije
                      child: const Text(
                        'Zaboravili ste lozinku?',
                        style: TextStyle(color: darkBrownColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // GUMB ZA PRIJAVU
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: darkBrownColor,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBrownColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Prijava',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  const Spacer(flex: 2),

                  // Link na registraciju
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Nemate račun?'),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/ekrani/registracija',
                        ),
                        child: const Text(
                          'Registrirajte se',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkBrownColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputFieldColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        // Ako je polje za lozinku, kontrolira se sakrivanje preko stanja _passwordObscured
        obscureText: isPassword ? _passwordObscured : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: hintTextColor),
          prefixIcon: Icon(icon, color: hintTextColor),
          // POPRAVAK: Ako je lozinka, dodajemo interaktivno oko na kraj polja
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _passwordObscured ? Icons.visibility_off : Icons.visibility,
                    color: hintTextColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordObscured = !_passwordObscured;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Color color;
  CirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}