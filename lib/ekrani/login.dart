import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../dekor.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _LoginState();
}

class _LoginState extends State<login> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordObscured = true;

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite email i lozinku')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prijava korisnika
      await _authService.prijavaKorisnika(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // 2. Dohvaćamo ulogu iz Supabase user metadata
      final user = Supabase.instance.client.auth.currentUser;
      final String uloga = user?.userMetadata?['uloga'] ?? 'kandidat';

      if (mounted) {
        // 3. Dinamičko usmjeravanje ovisno o ulozi
        if (uloga == 'poslodavac') {
          Navigator.pushReplacementNamed(context, '/ekrani/jednostavni_ekran');
        } else {
          Navigator.pushReplacementNamed(context, '/ekrani/glavni_ekran');
        }
      }
    } on AuthApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
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
          SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
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
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(boje, isDark)
              : _buildMobileView(boje),
        ),
      ),
    );
  }

  Widget _buildWebView(QuickJobsColors boje, bool isDark) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.28)
        : (boje.A ?? Colors.black).withValues(alpha: 0.08);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            color: boje.C?.withValues(alpha: 1.0),
            border: Border(
              bottom: BorderSide(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                tooltip: 'Natrag',
              ),
              const SizedBox(width: 12),
              Text(
                'QuickJobs',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: boje.A,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: boxPozadina,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: (boje.A ?? Colors.black).withValues(
                        alpha: isDark ? 0.18 : 0.12,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleSection(boje),
                      const SizedBox(height: 32),
                      ..._buildFormFieldsAndActions(boje),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          _buildTitleSection(boje),
          const SizedBox(height: 48),
          ..._buildFormFieldsAndActions(boje),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTitleSection(QuickJobsColors boje) {
    return Column(
      children: [
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
      ],
    );
  }

  List<Widget> _buildFormFieldsAndActions(QuickJobsColors boje) {
    return [
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
      const SizedBox(height: 24),
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
      const SizedBox(height: 24),
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
    ];
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