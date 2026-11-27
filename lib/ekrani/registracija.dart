import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../services/auth_service.dart';
import 'opciUvjeti.dart';
import '../dekor.dart';

class RegistracijaEkran extends StatefulWidget {
  const RegistracijaEkran({super.key});

  @override
  State<RegistracijaEkran> createState() => _RegistracijaEkranState();
}

class _RegistracijaEkranState extends State<RegistracijaEkran> {
  final AuthService _authService = AuthService();

  final _imeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _lozinkaController = TextEditingController();

  bool _prihvacamUvjete = false;
  bool _isLoading = false;
  bool _sakrijLozinku = true;

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
      await _authService.registrirajKorisnika(
        email: _emailController.text,
        password: _lozinkaController.text,
        punoIme: _imeController.text,
        telefon: _telefonController.text,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildFormChildren(boje, pokaziMobilniBack: false),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFormChildren(boje, pokaziMobilniBack: true),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren(
    QuickJobsColors boje, {
    required bool pokaziMobilniBack,
  }) {
    return [
      if (pokaziMobilniBack)
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
          fontSize: pokaziMobilniBack ? 36 : 30,
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
      const SizedBox(height: 32),
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
      _buildCheckbox('', _prihvacamUvjete, (value) {
        setState(() => _prihvacamUvjete = value!);
      }, boje, isLegal: true),
      const SizedBox(height: 32),
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
      const SizedBox(height: 24),
    ];
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
        obscureText: isPassword ? _sakrijLozinku : false,
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
          prefixIcon: Icon(icon, color: boje.A?.withValues(alpha: 1.0)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _sakrijLozinku ? Icons.visibility_off : Icons.visibility,
                    color: boje.A?.withValues(alpha: 0.75),
                  ),
                  onPressed: () {
                    setState(() {
                      _sakrijLozinku = !_sakrijLozinku;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 10,
          ),
        ),
      ),
    );
  }

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
              unselectedWidgetColor: boje.A,
            ),
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: boje.A,
              checkColor: boje.bg,
              side: BorderSide(
                color: boje.A!,
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