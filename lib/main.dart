import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/table_lookup_service.dart';
import 'viewmodels/table_lookup_view_model.dart' as table_view_model;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (context) => table_view_model.TableLookupViewModel(
            service: TableLookupService(
              authService: context.read<AuthService>(),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Table Checking App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D5FEF)),
          scaffoldBackgroundColor: const Color(0xFFEDE9F6),
          textTheme: GoogleFonts.robotoCondensedTextTheme().copyWith(
            headlineLarge:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w700),
            headlineMedium:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w700),
            headlineSmall:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w600),
            titleLarge:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w600),
            titleMedium:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w600),
            bodyLarge: GoogleFonts.robotoCondensed(fontWeight: FontWeight.w400),
            bodyMedium:
                GoogleFonts.robotoCondensed(fontWeight: FontWeight.w400),
            bodySmall: GoogleFonts.robotoCondensed(fontWeight: FontWeight.w300),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: Colors.black12),
            ),
            hintStyle: TextStyle(color: Colors.black54),
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(52)),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.black, width: 1.4),
                ),
              ),
              backgroundColor:
                  MaterialStateProperty.all(const Color(0xFFF9D66F)),
              foregroundColor:
                  MaterialStateProperty.all(const Color(0xFF1F2937)),
              shadowColor:
                  MaterialStateProperty.all(Colors.black.withOpacity(0.35)),
              elevation: MaterialStateProperty.all(8),
              textStyle: MaterialStateProperty.all(const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              )),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
