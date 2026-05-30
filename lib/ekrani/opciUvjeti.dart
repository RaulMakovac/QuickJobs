import 'package:flutter/material.dart';
import '../dekor.dart';

class UvjetiKoristenjaEkran extends StatelessWidget {
  const UvjetiKoristenjaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    const tamnoSmedja = Color(0xFF4A2C29);

    return Scaffold(
      backgroundColor: const Color(0xFFE5D9D6),
      body: PozadinaKrugovi(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, tamnoSmedja),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: tamnoSmedja.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Zadnja izmjena: 10. svibnja 2026.",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSekcija("1. Opće odredbe", 
                          "Dobrodošli u QuickJobs. Ovi Opći uvjeti korištenja uređuju pristup i korištenje mobilne aplikacije QuickJobs. Korištenjem Aplikacije, korisnik potvrđuje da je upoznat s ovim uvjetima te da ih u cijelosti prihvaća."),
                        _buildSekcija("2. Opis usluge", 
                          "QuickJobs je digitalna platforma koja služi kao posrednik između Naručitelja (Klijenta) koji objavljuje oglas i Izvršitelja (Radnika) koji se na njega prijavljuje. QuickJobs nije poslodavac niti agencija za zapošljavanje."),
                        _buildSekcija("3. Registracija i Sigurnost", 
                          "Korisnik mora imati najmanje 18 godina za korištenje Aplikacije. Korisnik je isključivo odgovoran za točnost unesenih podataka i čuvanje tajnosti svoje lozinke."),
                        _buildSekcija("4. Odgovornost za rad i plaćanje", 
                          "Dogovor o isplati naknade vrši se izravno između Naručitelja i Izvršitelja. QuickJobs ne jamči isplatu niti sudjeluje u transakcijama. Korisnici su sami odgovorni za porezne obveze."),
                        _buildSekcija("5. Isključenje odgovornosti", 
                          "QuickJobs ne snosi odgovornost za kvalitetu rada, ozljede na radu, niti bilo kakvu štetu nastalu dogovorom putem platforme. Koristite usluge na vlastitu odgovornost."),
                        _buildSekcija("6. Pravila ponašanja", 
                          "Zabranjeno je objavljivanje ilegalnog sadržaja, vrijeđanje korisnika ili manipulacija recenzijama. Kršenje pravila rezultirat će trajnim blokiranjem profila."),
                        _buildSekcija("7. GDPR i Zaštita podataka", 
                          "Vaši podaci obrađuju se u skladu s EU GDPR regulativom. Prikupljamo samo nužne podatke za povezivanje radnika i klijenata."),
                        _buildSekcija("8. Rješavanje sporova", 
                          "U slučaju spora, nadležan je sud prema sjedištu vlasnika Aplikacije (Hrvatska), uz primjenu zakona o zaštiti potrošača Europske unije."),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            "Hvala što koristite QuickJobs!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tamnoSmedja,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color boja) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
          const Expanded(
            child: Text(
              "Uvjeti korištenja",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A2C29),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSekcija(String naslov, String tekst) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            naslov,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A2C29),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tekst,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5, // Povećan razmak redova za lakše čitanje
            ),
          ),
        ],
      ),
    );
  }
}