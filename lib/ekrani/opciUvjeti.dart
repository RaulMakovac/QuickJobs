import 'package:flutter/material.dart';
import '../dekor.dart';

class UvjetiKoristenjaEkran extends StatelessWidget {
  const UvjetiKoristenjaEkran({super.key});

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
              ? _buildWebView(context, boje, isDark)
              : _buildMobileView(context, boje),
        ),
      ),
    );
  }

  Widget _buildWebView(
    BuildContext context,
    QuickJobsColors boje,
    bool isDark,
  ) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.08)
        : (boje.A ?? Colors.black).withValues(alpha: 0.10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: (boje.C ?? boje.B)?.withValues(alpha: 1.0),
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
                'Uvjeti korištenja',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: boje.A,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: boxPozadina,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (boje.A ?? Colors.black).withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                  ),
                ),
                child: _buildSadrzaj(boje),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, QuickJobsColors boje) {
    return Column(
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
            child: _buildSadrzaj(boje),
          ),
        ),
      ],
    );
  }

  Widget _buildSadrzaj(QuickJobsColors boje) {
    return SingleChildScrollView(
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
          _buildSekcija(
            "1. Opće odredbe",
            "Dobrodošli u QuickJobs. Ovi Opći uvjeti korištenja uređuju pristup i korištenje aplikacije i web sučelja QuickJobs. Korištenjem platforme korisnik potvrđuje da je upoznat s ovim uvjetima te da ih u cijelosti prihvaća.",
            boje,
          ),
          _buildSekcija(
            "2. Opis usluge",
            "QuickJobs je digitalna platforma koja služi kao posrednik između Naručitelja (Klijenta) koji objavljuje oglas za jednokratni ili povremeni posao i Izvršitelja koji se na njega prijavljuje. QuickJobs nije poslodavac, agencija za privremeno zapošljavanje niti platni posrednik.",
            boje,
          ),
          _buildSekcija(
            "3. Registracija i sigurnost računa",
            "Korisnik mora imati najmanje 18 godina za korištenje platforme. Korisnik je odgovoran za točnost podataka u svom profilu, zakonitost objavljenih oglasa i poruka te čuvanje tajnosti podataka za prijavu.",
            boje,
          ),
          _buildSekcija(
            "4. Odgovornost za rad i plaćanje",
            "Svi dogovori o opsegu posla, uvjetima i isplati naknade sklapaju se izravno između Naručitelja i Izvršitelja. QuickJobs ne jamči isplatu, ne naplaćuje poslove unutar aplikacije i ne sudjeluje u financijskim transakcijama. Korisnici samostalno odgovaraju za svoje porezne i druge zakonske obveze.",
            boje,
          ),
          _buildSekcija(
            "5. Isključenje odgovornosti",
            "QuickJobs ne jamči neprekidnu dostupnost usluge u svakom trenutku niti snosi odgovornost za kvalitetu obavljenog rada, ozljede, materijalnu štetu ili sporove nastale između korisnika. Korištenje platforme i dogovoreni poslovi odvijaju se na vlastitu odgovornost korisnika.",
            boje,
          ),
          _buildSekcija(
            "6. Pravila ponašanja i moderiranje",
            "Zabranjeno je objavljivanje nezakonitog, obmanjujućeg ili uvredljivog sadržaja, uznemiravanje, zlouporaba sustava prijava te lažno ocjenjivanje ili manipulacija recenzijama. Kršenje pravila može dovesti do uklanjanja sadržaja, ograničenja pristupa ili trajnog blokiranja računa.",
            boje,
          ),
          _buildSekcija(
            "7. GDPR i zaštita osobnih podataka",
            "Osobni podaci obrađuju se u skladu s Uredbom (EU) 2016/679 (GDPR) i važećim propisima o zaštiti podataka:\n"
                "• Koji se podaci prikupljaju: podaci računa i profila (npr. ime i prezime, e-mail adresa, telefonski broj, korisnička ocjena), sadržaj oglasa i prijava, poruke u chatu, podaci o lokaciji/adresi (kada se oglas veže uz lokaciju ili kartu) te tehnički podaci potrebni za rad i sigurnost sustava.\n"
                "• Svrha i pravna osnova obrade: podaci se koriste isključivo za kreiranje i održavanje računa, povezivanje naručitelja i izvršitelja, komunikaciju oko oglasa, prikaz recenzija i sprječavanje zlouporaba (izvršavanje usluge/ugovora i legitimni interes), dok se neobvezni podaci koriste u skladu s vašim izborom.\n"
                "• Gdje se podaci pohranjuju i kome su dostupni: podaci se pohranjuju i obrađuju u backend infrastrukturi aplikacije (Supabase / PostgreSQL) i povezanim tehničkim servisima potrebnim za isporuku usluge (uključujući karte/lokacijske upite prema odabranim servisima). Osnovni profilni podaci i oglasi vidljivi su drugim korisnicima u mjeri potrebnoj za suradnju i kontakt oko posla, dok se podaci ne prodaju trećim stranama u marketinške svrhe.\n"
                "• Rok čuvanja i sigurnost: podaci se čuvaju dok je račun aktivan ili koliko je nužno za ispunjenje svrhe i zakonskih obveza, uz primjenu tehničkih i organizacijskih mjera zaštite (uključujući kontrole pristupa na razini baze podataka).",
            boje,
          ),
          _buildSekcija(
            "8. Vaša prava prema GDPR-u",
            "Korisnik ima pravo zatražiti pristup svojim osobnim podacima, njihov ispravak ili dopunu, brisanje računa i pripadajućih podataka (kada ne postoji zakonska obveza daljnjeg čuvanja), ograničenje obrade, prenosivost podataka te prigovor na obradu. Korisnik također ima pravo podnijeti pritužbu nadzornom tijelu (u Hrvatskoj: Agencija za zaštitu osobnih podataka — AZOP).",
            boje,
          ),
          _buildSekcija(
            "9. Rješavanje sporova i izmjene uvjeta",
            "QuickJobs može povremeno ažurirati ove Uvjete korištenja, pri čemu se datum zadnje izmjene navodi na vrhu dokumenta. Za tumačenje ovih uvjeta i rješavanje eventualnih sporova mjerodavno je pravo Republike Hrvatske i EU propisi, uz nadležnost stvarno nadležnog suda u Republici Hrvatskoj.",
            boje,
          ),
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