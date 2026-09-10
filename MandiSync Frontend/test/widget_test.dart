// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mandisync_flutter/main.dart';
import 'package:mandisync_flutter/providers/app_provider.dart';
import 'package:mandisync_flutter/providers/auth_provider.dart';
import 'package:mandisync_flutter/providers/market_provider.dart';
import 'package:mandisync_flutter/providers/crop_provider.dart';
import 'package:mandisync_flutter/providers/logistics_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MandiSyncApp smoke test', (WidgetTester tester) async {
    // Build our app with providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MarketProvider()),
          ChangeNotifierProvider(create: (_) => CropProvider()),
          ChangeNotifierProvider(create: (_) => LogisticsProvider()),
        ],
        child: const MandiSyncApp(),
      ),
    );

    // Verify that MandiSyncApp widget renders
    expect(find.byType(MandiSyncApp), findsOneWidget);
  });
}
