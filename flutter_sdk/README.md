# MandiSync Flutter SDK & UI Integration Guide

This directory contains type-safe Dart models, API clients, and pre-built `fl_chart` widgets designed to integrate seamlessly into your Flutter application.

---

## 1. Required Dependencies

Add the following to your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  fl_chart: ^0.68.0
```

---

## 2. Directory Structure

Copy the `flutter_sdk/lib/` contents into your Flutter project's `lib/` directory:

```
lib/
├── models/
│   ├── price_forecast.dart       # Forecast points with .toFlSpot() helpers
│   ├── market_price.dart         # Agmarknet live price records
│   ├── crop.dart                 # Crop catalog & MSP
│   └── logistics.dart            # Delivery quotes & Provider fleet
├── services/
│   └── mandisync_api_service.dart # Type-safe API client
└── widgets/
    └── mandi_price_chart_widget.dart # Ready-to-render fl_chart line graph
```

---

## 3. Quick Usage Examples

### A. Rendering the 7-Day AI Price Forecast Chart

```dart
import 'package:flutter/material.dart';
import 'package:your_app/services/mandisync_api_service.dart';
import 'package:your_app/models/price_forecast.dart';
import 'package:your_app/widgets/mandi_price_chart_widget.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  // Use http://10.0.2.2:8000 for Android Emulator, http://localhost:8000 for iOS/Web
  final apiService = MandiSyncApiService(baseUrl: 'http://10.0.2.2:8000');
  late Future<PriceForecastResponse> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = apiService.getPriceForecast(
      commodity: 'Onion',
      market: 'Lasalgaon',
      days: 7,
      modalPrice: 2450.0,
      arrivals: 350.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mandi Price AI Forecast')),
      body: FutureBuilder<PriceForecastResponse>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return MandiPriceForecastChart(
            forecastData: snapshot.data!,
            showConfidenceBands: true,
          );
        },
      ),
    );
  }
}
```

### B. Fetching Live Agmarknet Mandi Prices

```dart
final records = await apiService.getMarketPrices(
  cropName: 'Wheat',
  limit: 20,
);
```

### C. Calculating Smart Logistics Quote with Backhaul Discounts

```dart
final quote = await apiService.requestDeliveryQuote(
  DeliveryQuoteRequest(
    origin: 'Nashik',
    destination: 'Mumbai',
    weightKg: 1500,
    distanceKm: 165,
    cropType: 'Onion',
  ),
);

print('Estimated Cost: ₹${quote.estimatedCostInr}');
print('Backhaul Discount: ${quote.isBackhaulDiscount}');
```
