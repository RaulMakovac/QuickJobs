import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ekrani/intro.dart';
import 'ekrani/registracija.dart'; 
import 'ekrani/login.dart';
import 'ekrani/odabir.dart';
import 'ekrani/glavni_ekran.dart';
import 'ekrani/objava_oglasa.dart';
import 'ekrani/job_hub.dart';
import 'ekrani/moji_oglasi.dart';
import 'ekrani/korisnicki_profil.dart';
import 'ekrani/moje_prijave.dart';
import 'ekrani/chat_hub.dart';
import 'dekor.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Učitavanje .env datoteke
  await dotenv.load(fileName: ".env");
  // Inicijalizacija Supabasea koristeći dotenv
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,
  ),
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickJobs',
      debugShowCheckedModeBanner: false, 
      builder: (context, child) {
    return PozadinaKrugovi(
      child: child ?? const SizedBox(),
    );
  },

     //initialRoute: '/ekrani/glavni_ekran',
     initialRoute: '/',

    // rute
    routes: {
      '/': (context) => const intro(),
      '/ekrani/registracija': (context) => const RegistracijaEkran(),
      '/ekrani/login': (context) => const login(),
      '/ekrani/odabir': (context) => const odabir(),
      '/ekrani/glavni_ekran': (context) => const glavni_ekran(),
      '/ekrani/objava_oglasa': (context) => const ObjavaOglasa(),
      '/ekrani/job_hub': (context) => const MojiPosloviHub(),
      '/ekrani/moji_oglasi': (context) => const MojiOglasi(),
      '/ekrani/korisnicki_profil': (context) => const KorisnickiProfil(),
      '/ekrani/moje_prijave': (context) => const MojePrijaveEkran(),
      '/ekrani/chat_hub': (context) => const ChatHub(),
      

    },
  );
  }
}

