import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart'; // Uvoz centraliziranih boja i teme

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
  bool _passwordObscured = true;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
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
    // Dohvaćamo definirane boje iz dekor.dart
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C, // Koristi globalni sustav krugova
        child: SafeArea(
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
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 26,
                        color: boje.A,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // NASLOV
                Text(
                  'Dobrodošli natrag',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: boje.A,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prijavite se u svoj QuickJobs račun',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: boje.A),
                ),

                const SizedBox(height: 48),

                // INPUT POLJA
                _buildInputField(
                  _emailController,
                  'E-mail adresa',
                  Icons.email,
                  boje,
                  isEmail: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  _passwordController,
                  'Lozinka',
                  Icons.lock,
                  boje,
                  isPassword: true,
                ),

                const SizedBox(height: 12),

                // Zaboravljena lozinka
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, 
                    child: Text(
                      'Zaboravili ste lozinku?',
                      style: TextStyle(color: boje.A),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // GUMB ZA PRIJAVU
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: boje.A,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: boje.A,
                          foregroundColor: boje.bg,
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
                    Text('Nemate račun?', style: TextStyle(color: boje.A)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/ekrani/registracija',
                      ),
                      child: Text(
                        'Registrirajte se',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: boje.A,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: boje.C,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _passwordObscured : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        style: TextStyle(color: boje.A, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: boje.A?.withValues(alpha: 0.65),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon, 
            color: boje.A?.withValues(alpha: 0.75),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _passwordObscured ? Icons.visibility_off : Icons.visibility,
                    color: boje.A?.withValues(alpha: 0.75),
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