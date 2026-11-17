import 'package:flutter/material.dart';
import '../dekor.dart';

class UvjetiKoristenjaEkran extends StatelessWidget {
  const UvjetiKoristenjaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, boje),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: boje.C,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Zadnja izmjena: 10. svibnja 2026.",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: boje.A?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSekcija("1. Opće odredbe", 
                          "Dobrodošli u QuickJobs. Ovi Opći uvjeti korištenja uređuju pristup i korištenje mobilne aplikacije QuickJobs. Korištenjem Aplikacije, korisnik potvrđuje da je upoznat s ovim uvjetima te da ih u cijelosti prihvaća.", boje),
                        _buildSekcija("2. Opis usluge", 
                          "QuickJobs je digitalna platforma koja služi kao posrednik između Naručitelja (Klijenta) koji objavljuje oglas i Izvršitelja (Radnika) koji se na njega prijavljuje. QuickJobs nije poslodavac niti agencija za zapošljavanje.", boje),
                        _buildSekcija("3. Registracija i Sigurnost", 
                          "Korisnik mora imati najmanje 18 godina za korištenje Aplikacije. Korisnik je isključivo odgovoran za točnost unesenih podataka i čuvanje tajnosti svoje lozinke.", boje),
                        _buildSekcija("4. Odgovornost za rad i plaćanje", 
                          "Dogovor o isplati naknade vrši se izravno između Naručitelja i Izvršitelja. QuickJobs ne jamči isplatu niti sudjeluje u transakcijama. Korisnici su sami odgovorni za porezne obveze.", boje),
                        _buildSekcija("5. Isključenje odgovornosti", 
                          "QuickJobs ne snosi odgovornost za kvalitetu rada, ozljede na radu, niti bilo kakvu štetu nastalu dogovorom putem platforme. Koristite usluge na vlastitu odgovornost.", boje),
                        _buildSekcija("6. Pravila ponašanja", 
                          "Zabranjeno je objavljivanje ilegalnog sadržaja, vrijeđanje korisnika ili manipulacija recenzijama. Kršenje pravila rezultirat će trajnim blokiranjem profila.", boje),
                        _buildSekcija("7. GDPR i Zaštita podataka", 
                          "Vaši podaci obrađuju se u skladu s EU GDPR regulativom. Prikupljamo samo nužne podatke za povezivanje radnika i klijenata.", boje),
                        _buildSekcija("8. Rješavanje sporova", 
                          "U slučaju spora, nadležan je sud prema sjedištu vlasnika Aplikacije (Hrvatska), uz primjenu zakona o zaštiti potrošača Europske unije.", boje),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            "Hvala što koristite QuickJobs!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: boje.A,
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

  Widget _buildHeader(BuildContext context, QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: boje.A),
          ),
          Expanded(
            child: Text(
              "Uvjeti korištenja",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSekcija(String naslov, String tekst, QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            naslov,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: boje.A,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tekst,
            style: TextStyle(
              fontSize: 14,
              color: boje.A?.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}