import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvjera {
  static final supabase = Supabase.instance.client;

  /// Provjerava je li trenutni korisnik baniran.
  /// Vraća poruku s datumom do kada traje ban, ili null ako korisnik nije baniran.
  static Future<String?> ProvjeriBanKorisnika() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // Povlačimo podatke o banu iz profiles tablice
      final data = await supabase
          .from('profiles')
          .select('baniran_do, trajno_baniran')
          .eq('id', user.id)
          .single();

      // 1. Provjera trajnog bana
      if (data['trajno_baniran'] == true) {
        return "Vaš račun je trajno baniran zbog višestrukog kršenja pravila.";
      }

      // 2. Provjera privremenog bana (na 7 dana)
      if (data['baniran_do'] != null) {
        final banDo = DateTime.parse(data['baniran_do']);
        if (banDo.isAfter(DateTime.now())) {
          // Računa koliko je dana/sati ostalo
          final preostalo = banDo.difference(DateTime.now());
          if (preostalo.inDays > 0) {
            return "Zabranjeno vam je korištenje aplikacije narednih ${preostalo.inDays} dana zbog prevelikog broja reporta.";
          } else {
            return "Zabranjeno vam je korištenje aplikacije još ${preostalo.inHours} sati zbog prevelikog broja reporta.";
          }
        }
      }
    } catch (e) {
      debugPrint("Greška pri provjeri bana: $e");
    }
    return null; // Korisnik je čist
  }

  /// Prikazuje Pop-up dijalog i izbacuje korisnika na Intro ekran
  static void prikaziBanDialog(BuildContext context, String poruka) {
    showDialog(
      context: context,
      barrierDismissible: false, // Korisnik ne može kliknuti sa strane da zatvori pop-up
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text("Pristup odbijen", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(poruka),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A2C29)),
            onPressed: () async {
              // Odjavi korisnika iz Supabase sessiona kako se ne bi mogao automatski ulogirati
              await supabase.auth.signOut();
              
              if (context.mounted) {
                // Vrati ga na Intro/Login ekran i pobriši svu povijest navigacije natrag
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            child: const Text("U redu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}