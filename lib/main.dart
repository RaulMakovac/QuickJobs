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
import 'ekrani/jednostavni_ekran.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    bool isOverflowError = details.toString().contains('Bottom overflowed');
    if (isOverflowError) return const SizedBox.shrink();
    return ErrorWidget(details.exception);
  };

  // Sigurno učitavanje .env datoteke s hvatanjem greške
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('UPOZORENJE: Nije uspjelo učitavanje .env datoteke: $e');
  }

  // Inicijalizacija Supabasea uz sigurnu provjeru (fallback ako dotenv faila)
  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'https://ovdje-stavi-fallback-url-za-test.supabase.co';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'fallback-anon-key';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
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
    // Slušamo promjene iz themeNotifier-a definiranog u dekor.dart
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, trenutniMod, child) {
        return MaterialApp(
          title: 'QuickJobs',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: trenutniMod, // Ovdje sada dinamički mijenja temu

          builder: (context, child) {
            return PozadinaKrugovi(
              child: child ?? const SizedBox(),
            );
          },

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
            '/ekrani/jednostavni_ekran': (context) => const JednostavniIzbornik(),
          },
        );
      },
    );
  }
}