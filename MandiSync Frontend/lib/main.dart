// =========================================================
// MANDISYNC FLUTTER — MAIN ENTRY POINT
// Ministry of Agriculture & Farmers Welfare Platform
// Matches Reference Design Layout & Structure
// =========================================================

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/mandi_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/markets_screen.dart';
import 'screens/crop_listing_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/logistics_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const MandiSyncApp());
}

class MandiSyncApp extends StatelessWidget {
  const MandiSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MandiSync — Agriculture Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B7A4B),
          primary: const Color(0xFF0B7A4B),
          secondary: const Color(0xFF075B38),
          surface: const Color(0xFFF6F9F7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF123B2A),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF123B2A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCFDAD4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCFDAD4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0B7A4B), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B7A4B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B7A4B),
            side: const BorderSide(color: Color(0xFF0B7A4B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFDFE7E2)),
          ),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  Map<String, String>? _analyticsParams;

  void _onDestinationSelected(int index, {Map<String, String>? params}) {
    setState(() {
      _selectedIndex = index;
      if (params != null) {
        _analyticsParams = params;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final pages = [
      HomeScreen(onNavigate: _onDestinationSelected),
      MarketsScreen(onNavigateWithParams: _onDestinationSelected),
      const CropListingScreen(),
      AnalyticsScreen(initialParams: _analyticsParams),
      const LogisticsScreen(),
      ProfileScreen(onStateChange: () => setState(() {})),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Government Header & MandiSync Navigation Bar
            MandiNavBar(
              selectedIndex: _selectedIndex,
              onNavigate: _onDestinationSelected,
              onStateChange: () => setState(() {}),
            ),

            // Active Screen Content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFEAF7F0),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF0B7A4B)), label: "Home"),
                NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront, color: Color(0xFF0B7A4B)), label: "Markets"),
                NavigationDestination(icon: Icon(Icons.grass_outlined), selectedIcon: Icon(Icons.grass, color: Color(0xFF0B7A4B)), label: "Sell"),
                NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics, color: Color(0xFF0B7A4B)), label: "AI Forecast"),
                NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping, color: Color(0xFF0B7A4B)), label: "Logistics"),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF0B7A4B)), label: "Profile"),
              ],
            ),
    );
  }
}
