import 'package:flutter/material.dart';
import '/ekrani/glavni_ekran.dart'; // Ovdje je tvoj Oglas model s autorId-om
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dekor.dart';
import '/ekrani/korisnicki_profil.dart';

class DetaljiOglasa extends StatelessWidget {
  final Oglas oglas;

  const DetaljiOglasa({super.key, required this.oglas});

  static const bgColor = Color(0xFFE5D9D6);
  static const darkBrown = Color(0xFF4A2C29);
  static const cardColor = Color(0xFF8F6E68);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: PozadinaKrugovi(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 200),
            child: Column(
              children: [
                _buildAppBar(context),
                const SizedBox(height: 40),
                _buildJobTitleHeader(),
                const SizedBox(height: 30),
                
                // KLJUČNA PROMJENA: Prosljeđujemo context metodi
                _buildAuthorSection(context), 
                
                const SizedBox(height: 30),
                _buildDetailRow('Adresa: ${oglas.adresa}'),
                const SizedBox(height: 10),
                _buildDetailRow('Isplata: ${oglas.isplata}€'),
                const SizedBox(height: 25),
                _buildDescriptionCard(),
                const SizedBox(height: 50),
                _buildApplyButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- REKREIRANA FUNKCIONALNOST KAO U EKRANU "ZAPOSLI" ---
  Widget _buildAuthorSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Provjera postoji li autorId prije navigacije
        if (oglas.autorId != null && oglas.autorId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KorisnickiProfil(
                prikazaniKorisnikId: oglas.autorId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Profil autora trenutno nije dostupan."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSquareImage(),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 35, color: darkBrown),
                  const SizedBox(width: 8),
                  Text(
                    oglas.autorIme ?? 'Nepoznat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 43),
                child: Text(
                  'UVID U PROFIL POSLODAVCA',
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- OSTALI POMOĆNI WIDGETI ---

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 30),
        ),
        const Expanded(
          child: Text(
            'Opis oglasa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildJobTitleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: darkBrown,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        oglas.naslov,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        oglas.opis.isEmpty ? 'Nema opisa.' : oglas.opis,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handlePrijava(context),
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: const Icon(Icons.check, size: 55, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Prijavi se na posao!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _handlePrijava(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _showSnack(context, 'Morate biti prijavljeni!', isError: true);
      return;
    }

    try {
      await supabase.from('prijave').insert({
        'oglas_id': oglas.id,
        'korisnik_id': user.id,
      });

      if (context.mounted) {
        _showSnack(context, 'Uspješno prijavljeni!', isError: false);
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (context.mounted) _showSnack(context, 'Baza javlja: ${e.message}', isError: true);
    } catch (e) {
      if (context.mounted) _showSnack(context, 'Neočekivana greška: $e', isError: true);
    }
  }

  void _showSnack(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildSquareImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(Icons.image, color: Colors.white, size: 40),
    );
  }

  Widget _buildDetailRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}