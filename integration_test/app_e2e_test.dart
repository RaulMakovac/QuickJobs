import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quickjobs/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QuickJobs End-to-End (E2E) Cijeli Tok Test', () {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String email1 = 'korisnik1_$timestamp@test.com';
    final String pass1 = 'Lozinka123!';
    final String ime1 = 'Prvi Korisnik';

    final String email2 = 'kandidat_$timestamp@test.com';
    final String pass2 = 'Lozinka123!';
    final String ime2 = 'Kandidat Korisnik';

    final String nazivOglasa = 'Popravak racunala $timestamp';

    testWidgets('Glavni E2E test prolaz kroz cijelu aplikaciju', (
      WidgetTester tester,
    ) async {
      // 1. Pokretanje aplikacije
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ==========================================
      // KORAK 1: REGISTRACIJA PRVOG KORISNIKA
      // ==========================================

      final Finder introGumb = find.text('Započnite');
      if (tester.any(introGumb)) {
        await tester.tap(introGumb);
        await tester.pumpAndSettle();
      }

      final Finder regLink = find.text('Registrirajte se');
      if (tester.any(regLink)) {
        await tester.tap(regLink);
        await tester.pumpAndSettle();
      }

      // Osiguravamo da su polja prisutna na ekranu prije upisivanja
      expect(find.byType(TextField), findsWidgets);

      // Unos prema redoslijedu polja na ekranu registracije (0: Ime, 1: Email, 2: Telefon, 3: Lozinka)
      await tester.enterText(find.byType(TextField).at(0), ime1);
      await tester.enterText(find.byType(TextField).at(1), email1);
      await tester.enterText(find.byType(TextField).at(2), '0911234567');
      await tester.enterText(find.byType(TextField).at(3), pass1);
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Registracija').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // ==========================================
      // KORAK 1.5: ODABIR ULOGE (npr. Tražim radnika)
      // ==========================================

      final Finder trazimRadnikaKartica = find.text('Tražim radnika');
      expect(trazimRadnikaKartica, findsOneWidget);
      await tester.tap(trazimRadnikaKartica);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // ==========================================
      // KORAK 2: JEDNOSTAVNI MENI I OBJAVA OGLASA
      // ==========================================

      if (tester.any(find.byIcon(Icons.add))) {
        await tester.tap(find.byIcon(Icons.add).first);
      } else {
        await tester.tap(find.text('Objavi novi oglas'));
      }
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);

      // Redoslijed polja za objavu oglasa
      await tester.enterText(find.byType(TextField).at(0), nazivOglasa);
      await tester.enterText(find.byType(TextField).at(1), 'Rijeka, Korzo 1');
      await tester.enterText(find.byType(TextField).at(2), '50');
      await tester.enterText(
        find.byType(TextField).at(3),
        'Trebana pomoc oko instalacije sustava.',
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      // ==========================================
      // KORAK 3: POSTAVKE I PROMJENA TEMA
      // ==========================================

      final Finder postavkeKartica = find.text('Postavke');
      if (tester.any(postavkeKartica)) {
        await tester.tap(postavkeKartica);
        await tester.pumpAndSettle();
      }

      // Pronalazimo opciju za temu bez obzira piše li svijetli ili tamni način rada
      final Finder temaOpcija = find.byWidgetPredicate((widget) {
        if (widget is Text) {
          final data = widget.data ?? '';
          return data.contains('Svijetli način rada') ||
              data.contains('Tamni način rada');
        }
        return false;
      });

      if (tester.any(temaOpcija)) {
        await tester.tap(temaOpcija.first);
        await tester.pumpAndSettle();
      }

      // Povratak natrag (provjeravamo obje moguće ikone za back gumb)
      final Finder backIcon1 = find.byIcon(Icons.arrow_back_ios_new);
      final Finder backIcon2 = find.byIcon(Icons.arrow_back);

      if (tester.any(backIcon1)) {
        await tester.tap(backIcon1.first);
        await tester.pumpAndSettle();
      } else if (tester.any(backIcon2)) {
        await tester.tap(backIcon2.first);
        await tester.pumpAndSettle();
      }

      // ==========================================
      // KORAK 4: PROFIL I ODJAVA (PRVI KORISNIK)
      // ==========================================

      // Profil je kartica s tekstom "Moj profil"
      final Finder mojProfilKartica = find.text('Moj profil');
      if (tester.any(mojProfilKartica)) {
        await tester.tap(mojProfilKartica);
        await tester.pumpAndSettle();
      }

      // Klik na specifičnu ikonu odjave na ekranu profila
      final Finder odjavaIkona = find.byIcon(Icons.logout_rounded);
      if (tester.any(odjavaIkona)) {
        await tester.tap(odjavaIkona);
        await tester.pumpAndSettle();
      }

      // Potvrda odjave unutar AlertDialog-a (tekst gumba je "Odjavi se")
      final Finder potvrdaOdjaveGumb = find.text('Odjavi se');
      expect(potvrdaOdjaveGumb, findsOneWidget);
      await tester.tap(potvrdaOdjaveGumb);

      // Čekamo da Supabase odjavi korisnika i vrati aplikaciju na početni ekran
      await tester.pumpAndSettle(const Duration(seconds: 4));
      // ==========================================
      // KORAK 5: LOGIN DRUGOG KORISNIKA (KANDIDAT)
      // ==========================================
      final Finder introGumb2 = find.text('Započnite');
      if (tester.any(introGumb2)) {
        await tester.tap(introGumb2);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TextField), findsWidgets);

      // Unos prema redoslijedu polja na ekranu registracije (0: Ime, 1: Email, 2: Telefon, 3: Lozinka)
      await tester.enterText(find.byType(TextField).at(0), ime2);
      await tester.enterText(find.byType(TextField).at(1), email2);
      await tester.enterText(find.byType(TextField).at(2), '0911234557');
      await tester.enterText(find.byType(TextField).at(3), pass2);
      await tester.pump();

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Registracija').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final Finder trazimRadnikaKartica2 = find.text('Tražim posao');
      expect(trazimRadnikaKartica2, findsOneWidget);
      await tester.tap(trazimRadnikaKartica2);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ==========================================
      // KORAK 6: PRIJAVA NA OGLAS OD STRANE KANDIDATA
      // ==========================================

      expect(find.text(nazivOglasa), findsOneWidget);
      await tester.tap(find.text(nazivOglasa));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.account_box).last);
      await tester.pumpAndSettle();

      final Finder odjavaIkona2 = find.byIcon(Icons.logout_rounded);
      if (tester.any(odjavaIkona2)) {
        await tester.tap(odjavaIkona2);
        await tester.pumpAndSettle();
      }

      // Potvrda odjave unutar AlertDialog-a (tekst gumba je "Odjavi se")
      final Finder potvrdaOdjaveGumb2 = find.text('Odjavi se');
      expect(potvrdaOdjaveGumb2, findsOneWidget);
      await tester.tap(potvrdaOdjaveGumb2);
      await tester.pumpAndSettle(
        const Duration(seconds: 4),
      ); // <-- OVO JE NEDOSTAJALO

      // ==========================================
      // KORAK 7: PONOVNI LOGIN PRVOG KORISNIKA I PRIHVATANJE KANDIDATA
      // ==========================================

      final Finder introGumb3 = find.text('Započnite');
      if (tester.any(introGumb3)) {
        await tester.tap(introGumb3);
        await tester.pumpAndSettle();
      }

      // Siguran klik na login link/gumb
      final Finder loginLink1 = find.text('Log in');
      final Finder prijaviteSeLink1 = find.text('Prijavite se');
      if (tester.any(loginLink1)) {
        await tester.tap(loginLink1.last);
        await tester.pumpAndSettle();
      } else if (tester.any(prijaviteSeLink1)) {
        await tester.tap(prijaviteSeLink1.last);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).at(0), email1);
      await tester.enterText(find.byType(TextField).at(1), pass1);
      await tester.pump();
      await tester.tap(find.text('Prijava'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Otvaranje ekrana "Moji oglasi"
      final Finder mojiOglasiKartica = find.text('Moji oglasi');
      if (tester.any(mojiOglasiKartica)) {
        await tester.tap(mojiOglasiKartica);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.list_alt_rounded))) {
        await tester.tap(find.byIcon(Icons.list_alt_rounded));
        await tester.pumpAndSettle();
      }

      // Klik na gumb "VIDI PRIJAVE" na kartici oglasa
      final Finder vidiPrijaveGumb = find.text('VIDI PRIJAVE');
      expect(vidiPrijaveGumb, findsOneWidget);
      await tester.tap(vidiPrijaveGumb);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Sada smo na ekranu Zaposli i tu se nalazi naš kandidat (ime2)
      expect(find.text(ime2), findsOneWidget);
      await tester.tap(find.text(ime2));
      await tester.pumpAndSettle();

      // Klik na gumb za prihvaćanje radnika
      final Finder prihvatiGumb = find.text('PRIHVATI');
      if (tester.any(prihvatiGumb)) {
        await tester.tap(prihvatiGumb);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Klik na ikonu chata na kartici oglasa (Icons.forum_rounded)[cite: 5]
      final Finder chatIkonaOglasa = find.byIcon(Icons.forum_rounded);
      if (tester.any(chatIkonaOglasa)) {
        await tester.tap(chatIkonaOglasa.first);
        await tester.pumpAndSettle();
      }

      final Finder chatKartica = find.text(
        ime2,
      ); // ili find.text(nazivOglasa) ako ti je draže
      await tester.pumpAndSettle(
        const Duration(seconds: 2),
      ); // Dajemo trenutak StreamBuilderu da dohvati podatke

      if (tester.any(chatKartica)) {
        await tester.tap(chatKartica.first);
        await tester.pumpAndSettle();
      }

      // Unos teksta poruke i slanje
      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(
        find.byType(TextField).first,
        'Pozdrav, prihvaćeni ste na posao! Možemo li krenuti?',
      );
      await tester.pump();

      final Finder sendGumb = find.byIcon(Icons.send);
      if (tester.any(sendGumb)) {
        await tester.tap(sendGumb);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Povratak iz chata natrag na izbornik
      if (tester.any(find.byIcon(Icons.arrow_back_ios_new))) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.arrow_back))) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
      }

      if (tester.any(find.byIcon(Icons.arrow_back_ios_new))) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.arrow_back))) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
      }

      if (tester.any(find.byIcon(Icons.arrow_back_ios_new))) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.arrow_back))) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byIcon(Icons.account_box).last);
      await tester.pumpAndSettle();

      final Finder odjavaIkona3 = find.byIcon(Icons.logout_rounded);
      if (tester.any(odjavaIkona3)) {
        await tester.tap(odjavaIkona3);
        await tester.pumpAndSettle();
      }

      // Potvrda odjave unutar AlertDialog-a (tekst gumba je "Odjavi se")
      final Finder potvrdaOdjaveGumb3 = find.text('Odjavi se');
      expect(potvrdaOdjaveGumb3, findsOneWidget);
      await tester.tap(potvrdaOdjaveGumb3);
      await tester.pumpAndSettle(
        const Duration(seconds: 4),
      ); // <-- OVO JE NEDOSTAJALO

      // ==========================================
      // KORAK 8: LOGIN KANDIDATA, SLANJE PORUKE
      // ==========================================

      if (tester.any(find.text('Započnite'))) {
        await tester.tap(find.text('Započnite'));
        await tester.pumpAndSettle();
      }
      if (tester.any(find.text('Log in'))) {
        await tester.tap(find.text('Log in').last);
        await tester.pumpAndSettle();
      } else if (tester.any(find.text('Prijavite se'))) {
        await tester.tap(find.text('Prijavite se').last);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).at(0), email2);
      await tester.enterText(find.byType(TextField).at(1), pass2);
      await tester.pump();
      await tester.tap(find.text('Prijava'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Umjesto naziva oglasa, kliknemo na karticu preko imena kandidata (ime2)
      final Finder chatKarticaKandidata = find.text(ime1);
      expect(chatKarticaKandidata, findsOneWidget);
      await tester.tap(chatKarticaKandidata);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Bok, spreman sam za posao!',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Povratak iz chata natrag
      if (tester.any(find.byIcon(Icons.arrow_back_ios_new))) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.arrow_back))) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
      }

      if (tester.any(find.byIcon(Icons.arrow_back_ios_new))) {
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.arrow_back))) {
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
      }

      // Odjava kandidata (account_box -> logout_rounded -> Odjavi se)
      if (tester.any(find.byIcon(Icons.account_box))) {
        await tester.tap(find.byIcon(Icons.account_box).last);
        await tester.pumpAndSettle();
      }
      if (tester.any(find.byIcon(Icons.logout_rounded))) {
        await tester.tap(find.byIcon(Icons.logout_rounded));
        await tester.pumpAndSettle();
      }
      if (tester.any(find.text('Odjavi se'))) {
        await tester.tap(find.text('Odjavi se'));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      // ==========================================
      // KORAK 9: LOGIN OBJAVITELJA I ODGOVOR
      // ==========================================

      if (tester.any(find.text('Započnite'))) {
        await tester.tap(find.text('Započnite'));
        await tester.pumpAndSettle();
      }
      if (tester.any(find.text('Log in'))) {
        await tester.tap(find.text('Log in').last);
        await tester.pumpAndSettle();
      } else if (tester.any(find.text('Prijavite se'))) {
        await tester.tap(find.text('Prijavite se').last);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(find.byType(TextField).at(0), email1);
      await tester.enterText(find.byType(TextField).at(1), pass1);
      await tester.pump();
      await tester.tap(find.text('Prijava'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Na jednostavnom izborniku poruke su kartica "Poruke" (ili ikona chat)
      if (tester.any(find.text('Poruke'))) {
        await tester.tap(find.text('Poruke'));
        await tester.pumpAndSettle();
      } else if (tester.any(find.byIcon(Icons.chat))) {
        await tester.tap(find.byIcon(Icons.chat));
        await tester.pumpAndSettle(const Duration(seconds: 4));
      }

      // Čekamo da se FutureBuilder i Stream osvježe i prikažu karticu s imenom kandidata (ime2)
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Pronalazimo karticu koja sadrži ime kandidata i tapnemo ju
      final Finder karticaKandidata = find.text(ime2);
      expect(karticaKandidata, findsWidgets);
      await tester.tap(karticaKandidata.first);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Čekamo ulazak u ChatIndividualni

      // Sada provjeravamo i unosimo poruku u individualnom chatu
      expect(find.byType(TextField), findsWidgets);
      await tester.enterText(
        find.byType(TextField).first,
        'Odlično, krećemo s radom.',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
    });
  });
}
