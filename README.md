# 🛠️ QuickJobs – Poveži se i odradi posao

QuickJobs je moderna Flutter aplikacija dizajnirana za brzo spajanje ljudi koji trebaju pomoć s obavljanjem sitnih poslova i lokalnih radnika (freelancera). Bilo da tražiš nekoga za popravak, dostavu ili čišćenje, QuickJobs omogućuje transparentnu komunikaciju i jednostavno upravljanje oglasima.

## ✨ Ključne Značajke

* **Pregled poslova:** Dinamička lista dostupnih oglasa s filtriranjem po isplati i lokaciji.
* **Upravljanje oglasima:** Kreiranje, ažuriranje i arhiviranje vlastitih oglasa.
* **Sustav prijava:** Korisnici se mogu prijaviti na poslove, a autori oglasa biraju najbolje kandidate.
* **Real-time Chat:** Integrirani sustav poruka za dogovaranje detalja unutar aplikacije.
* **Recenzije i ocjene:** Sustav povratnih informacija nakon svakog obavljenog posla.
* **Sticky UI komponente:** Moderno korisničko sučelje s interaktivnim elementima i fluidnim skrolanjem.

## 🚀 Tehnologije

* **Frontend:** [Flutter](https://flutter.dev) (Dart)
* **Backend & Baza:** [Supabase](https://supabase.com) (PostgreSQL)
* **Autentifikacija:** Supabase Auth
* **Upravljanje stanjem:** Stateful Widgets & Streams

## 📸 Screenshots

| Glavni Ekran | Detalji Oglasa | Chat |
| :---: | :---: | :---: |
| ![Glavni](https://via.placeholder.com/200x400?text=Glavni+Ekran) | ![Detalji](https://via.placeholder.com/200x400?text=Detalji+Oglasa) | ![Chat](https://via.placeholder.com/200x400?text=Chat+Hub) |
*(Napomena: Zamijeni ove linkove stvarnim slikama iz svog projekta)*

## 🛠️ Instalacija i Postavljanje

1.  **Kloniraj projekt:**
    ```bash
    git clone [https://github.com/tvoj-username/quickjobs.git](https://github.com/tvoj-username/quickjobs.git)
    ```
2.  **Instaliraj pakete:**
    ```bash
    flutter pub get
    ```
3.  **Konfiguracija baze:**
    * Kreiraj projekt na [Supabase](https://supabase.com).
    * Pokreni SQL skripte za tablice `oglasi`, `profiles`, `prijave` i `chat_sobe`.
    * Postavi RLS politike (Row Level Security).
4.  **Poveži aplikaciju:**
    * U `main.dart` unesi svoj `supabaseUrl` i `anonKey`.
5.  **Pokreni aplikaciju:**
    ```bash
    flutter run
    ```

## 📄 Licenca

Ovaj projekt je razvijen pod [MIT licencom](LICENSE).

---
*Razvijeno s ❤️ za QuickJobs zajednicu.*
