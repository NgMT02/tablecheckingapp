import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'services/auth_service.dart';
import 'services/menu_service.dart';
import 'services/now_serving_service.dart';
import 'services/order_service.dart';
import 'viewmodels/cart_view_model.dart';
import 'viewmodels/menu_view_model.dart';
import 'viewmodels/now_serving_view_model.dart';
import 'viewmodels/order_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(
          create: (context) => MenuService(
            authService: context.read<AuthService>(),
          ),
        ),
        Provider(
          create: (context) => OrderService(
            authService: context.read<AuthService>(),
          ),
        ),
        Provider(
          create: (context) => NowServingService(
            authService: context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => MenuViewModel(
            service: context.read<MenuService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(
          create: (context) => NowServingViewModel(
            service: context.read<NowServingService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderViewModel(
            service: context.read<OrderService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'UPM Cafe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFFD39A76),
            onPrimary: Colors.white,
            secondary: Color(0xFFE6B58F),
            onSecondary: Colors.white,
            surface: Color(0xFFFFF8F2),
            onSurface: Color(0xFF3D2B1F),
            background: Color(0xFFFFF6EE),
            onBackground: Color(0xFF3D2B1F),
            error: Color(0xFFB3261E),
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF6EE),
          textTheme: _buildTextTheme(),
          cardTheme: CardTheme(
            color: const Color(0xFFFFF8F2),
            elevation: 6,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFDFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFE7D6C6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFE7D6C6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFD39A76), width: 1.4),
            ),
            hintStyle: const TextStyle(color: Color(0xFF8A6B55)),
            labelStyle: const TextStyle(color: Color(0xFF6F4E37)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              minimumSize: MaterialStateProperty.all(const Size.fromHeight(50)),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              backgroundColor:
                  MaterialStateProperty.all(const Color(0xFFD39A76)),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              shadowColor:
                  MaterialStateProperty.all(Colors.black.withOpacity(0.16)),
              elevation: MaterialStateProperty.all(4),
              textStyle: MaterialStateProperty.all(const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              )),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B5E3C),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Color(0xFF3D2B1F),
            centerTitle: true,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

TextTheme _buildTextTheme() {
  final base = GoogleFonts.nunitoTextTheme();
  final display = GoogleFonts.dmSerifDisplay();
  return base.copyWith(
    displayLarge: display.copyWith(fontWeight: FontWeight.w700),
    displayMedium: display.copyWith(fontWeight: FontWeight.w700),
    displaySmall: display.copyWith(fontWeight: FontWeight.w700),
    headlineLarge: display.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: display.copyWith(fontWeight: FontWeight.w700),
    headlineSmall: display.copyWith(fontWeight: FontWeight.w700),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
  );
}
