import 'package:flutter/material.dart';
import '/ekrani/glavni_ekran.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      body: Stack(
        // Koristimo Stack za krugove u pozadini
        children: [
          // Pozadinski krugovi (vizualni detalj s tvog screenshota)
          Positioned(
            top: -50,
            left: -30,
            child: CircleAvatar(radius: 100, backgroundColor: Colors.white24),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  // Header s Back gumbom i Naslovom
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 30),
                      ),
                      const Expanded(
                        child: Text(
                          'Opis oglasa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Naslov posla u tamnom mjehuriću
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: darkBrown,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      oglas.naslov,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Redak s autorom i slikom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSquareImage(),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                size: 35,
                                color: darkBrown,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                oglas.autorIme ?? 'Nepoznat',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // OCJENA (Null handling)
                          const Padding(
                            padding: EdgeInsets.only(left: 43),
                            child: Text(
                              'Ocjena: Nema ocjena', // Ovdje će ići logika za zvjezdice kasnije
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Detalji (Adresa, Isplata)
                  _buildDetailRow('Adresa: ${oglas.adresa}'),
                  const SizedBox(height: 10),
                  _buildDetailRow('Isplata: ${oglas.isplata}€'),
                  const SizedBox(height: 25),

                  // Opis posla (Velika tamna kartica)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      oglas.opis.isEmpty ? 'Nema opisa.' : oglas.opis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Gumb za prijavu (Kvačica)
                  Column(
                    children: [
                      // Unutar tvoje build metode, zamijeni GestureDetector dio ovime:
                      GestureDetector(
                        onTap: () async {
                          final supabase = Supabase.instance.client;
                          final user = supabase.auth.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Morate biti prijavljeni!'),
                              ),
                            );
                            return;
                          }

                          try {
                            await supabase.from('prijave').insert({
                              'oglas_id': oglas.id,
                              'korisnik_id': user.id,
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Uspješno prijavljeni!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } on PostgrestException catch (e) {
                            // Ovdje smo definirali 'e'
                            if (context.mounted) {
                              // Sada koristimo 'e.message' jer je gore 'catch (e)'
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Baza javlja: ${e.message}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Općenita greška
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Neočekivana greška: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 55,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Prijavi se na posao!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
