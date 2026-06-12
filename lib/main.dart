import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mandato_novo/pages/home_page.dart';
import 'package:mandato_novo/pages/login_page.dart';
import 'package:mandato_novo/services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.initialize();

  runApp(MandatoApp(appState: appState));
}

class MandatoApp extends StatelessWidget {
  final AppState appState;

  const MandatoApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: Builder(
        builder: (context) {
          final isLoggedIn = context.watch<AppState>().loggedIn;
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Mandato',
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.white,
              primaryColor: const Color(0xFF111827),
              colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(
                secondary: const Color(0xFF7C3AED),
                primary: const Color(0xFF111827),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFF111827)),
                titleTextStyle: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textTheme: const TextTheme(
                headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF111827)),
                bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                ),
              ),
            ),
            home: isLoggedIn ? const HomePage() : const LoginPage(),
            routes: {
              '/home': (_) => const HomePage(),
              '/login': (_) => const LoginPage(),
            },
          );
        },
      ),
    );
  }
}
