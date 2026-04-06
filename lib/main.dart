import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/nostr_info_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RuaVivaApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/nostr-info',
      builder: (context, state) => const NostrInfoScreen(),
    ),
  ],
);

class RuaVivaApp extends StatelessWidget {
  const RuaVivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Rua Viva',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF009739),
          onPrimary: Colors.white,
          secondary: Color(0xFFFEDD00),
          onSecondary: Color(0xFF012169),
          tertiary: Color(0xFF012169),
          onTertiary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF012169),
          error: Color(0xFFB71C1C),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF012169), letterSpacing: -1.0),
          displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF012169), letterSpacing: -0.5),
          displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF012169)),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF012169)),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF012169)),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF012169)),
          bodyLarge: TextStyle(fontSize: 20, color: Color(0xFF012169), height: 1.4),
          bodyMedium: TextStyle(fontSize: 18, color: Color(0xFF012169), height: 1.4),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009739), // Brasil Green
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 72),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF012169),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF012169)),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 12,
          shadowColor: const Color(0xFF012169).withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
