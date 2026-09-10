import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'services/api_service.dart';

import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/market_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/logistics_provider.dart';

import 'screens/home_screen.dart';
import 'screens/markets_screen.dart';
import 'screens/crop_listing_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/logistics_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..checkBackendHealth()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => LogisticsProvider()),
      ],
      child: const MandiSyncApp(),
    ),
  );
}

class MandiSyncApp extends StatelessWidget {
  const MandiSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MandiSync — Smart Agriculture Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/markets': (context) => const MarketsScreen(),
        '/crop-listing': (context) => const CropListingScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/logistics': (context) => const LogisticsScreen(),
        '/signin': (context) => const SignInScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/stats': (context) => const StatsScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
