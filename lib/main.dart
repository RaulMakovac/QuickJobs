import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ekrani/intro.dart';
import 'ekrani/registracija.dart'; 
import 'ekrani/login.dart';
import 'ekrani/odabir.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Učitavanje .env datoteke
  await dotenv.load(fileName: ".env");

  // Inicijalizacija Supabasea koristeći dotenv
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickJobs',
      debugShowCheckedModeBanner: false, // Miče onaj "Debug" natpis u kutu
      
     initialRoute: '/', 
    
    // 2. Mapa svih stranica u aplikaciji
    routes: {
      '/': (context) => const intro(),
      '/ekrani/registracija': (context) => const registracija(),
      '/ekrani/login': (context) => const login(),
      '/ekrani/odabir': (context) => const odabir(),
    },
  );
  }
}

