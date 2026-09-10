import 'package:flutter/foundation.dart';

/// Centralized API Constants for MandiSync Frontend
/// All backend endpoints and configuration matching MandiSync FastAPI specifications.
class ApiConstants {
  // ---------------------------------------------------------------------------
  // Base URLs & Dynamic Host Resolution
  // ---------------------------------------------------------------------------
  static String? _customRootBase;

  /// Allows dynamically overriding the backend host URL at runtime (e.g. settings or tests)
  static void setBaseUrl(String url) {
    _customRootBase = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Automatically resolves the correct backend host:
  /// - Custom override if set
  /// - In web browser: uses the origin where the app is hosted (e.g. https://*.onrender.com or http://localhost:8000)
  /// - Defaults to http://localhost:8000 for local dev / mobile emulator
  static String get rootBase {
    if (_customRootBase != null && _customRootBase!.isNotEmpty) {
      return _customRootBase!;
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      // If served directly from Render, Railway, or local FastAPI on port 8000
      if (origin.contains('onrender.com') ||
          origin.contains('railway.app') ||
          origin.endsWith(':8000')) {
        return origin;
      }
    }
    return 'http://localhost:8000';
  }

  static const String apiPrefix = '/api/v1';
  static String get apiBase => '$rootBase$apiPrefix';

  // Documentation & Schema Endpoints
  static const String swaggerDocs = '/docs';
  static const String redocDocs = '/redoc';
  static const String openApiJson = '$apiPrefix/openapi.json';

  // ---------------------------------------------------------------------------
  // Storage Keys
  // ---------------------------------------------------------------------------
  static const String tokenKey = 'mandisyncToken';
  static const String userKey = 'mandisyncUser';

  // ---------------------------------------------------------------------------
  // 1. Authentication & User Management
  // ---------------------------------------------------------------------------
  static const String authLogin = '$apiPrefix/auth/login';
  static const String authRegister = '$apiPrefix/auth/register';
  static const String usersRegister = '$apiPrefix/users/register';
  static const String usersMe = '$apiPrefix/users/me';

  // ---------------------------------------------------------------------------
  // 2. Farmer Crop Listings (CRUD & ONDC Standardized)
  // ---------------------------------------------------------------------------
  static const String crops = '$apiPrefix/crops';
  static String cropById(dynamic cropId) => '$crops/$cropId';

  // ---------------------------------------------------------------------------
  // 3. Agmarknet Historical Market Prices (CRUD)
  // ---------------------------------------------------------------------------
  static const String marketPrices = '$apiPrefix/market-prices';
  static String marketPriceById(dynamic priceId) => '$marketPrices/$priceId';

  // ---------------------------------------------------------------------------
  // 4. AI Price Forecasting (XGBoost Engine)
  // ---------------------------------------------------------------------------
  static const String predict = '$apiPrefix/predict';
  static const String predictForecast = '$apiPrefix/predict/forecast';

  // ---------------------------------------------------------------------------
  // 5. Logistics Fleet & Backhaul Matching
  // ---------------------------------------------------------------------------
  static const String logisticsProviders = '$apiPrefix/logistics/providers';
  static String logisticsProviderById(dynamic id) => '$logisticsProviders/$id';
  static const String logisticsQuotes = '$apiPrefix/logistics/quotes';
  static const String matchBackhauls = '$apiPrefix/logistics/match-backhauls';
  static String matchBackhaulsById(dynamic id) => '$matchBackhauls/$id';

  // ---------------------------------------------------------------------------
  // 6. ONDC Beckn Protocol Webhooks & Catalog
  // ---------------------------------------------------------------------------
  static const String ondcSearch = '$apiPrefix/ondc/search';
  static const String ondcSelect = '$apiPrefix/ondc/select';
  static const String ondcCropListings = '$apiPrefix/ondc/crop_listings';
  static String ondcCropListingById(dynamic itemId) => '$ondcCropListings/$itemId';

  // ---------------------------------------------------------------------------
  // 7. Mock & Scaffold Endpoints (Frontend Unblocking)
  // ---------------------------------------------------------------------------
  static const String mockRegister = '$apiPrefix/register';
  static const String stats = '$apiPrefix/stats';
  static const String transactions = '$apiPrefix/transactions';
  static const String history = '$apiPrefix/history';
  static const String authAadhaarStart = '$apiPrefix/auth/aadhaar/start';
  static const String authAadhaarVerify = '$apiPrefix/auth/aadhaar/verify';
  static const String authDigilockerStart = '$apiPrefix/auth/digilocker/start';

  // ---------------------------------------------------------------------------
  // 8. System & Health
  // ---------------------------------------------------------------------------
  static const String root = '/';
  static const String health = '/health';

  // ---------------------------------------------------------------------------
  // Backwards-Compatible Aliases
  // ---------------------------------------------------------------------------
  static const String loginEndpoint = authLogin;
  static const String registerEndpoint = usersRegister;
  static const String registerAlt1Endpoint = authRegister;
  static const String registerAlt2Endpoint = mockRegister;
  static const String meEndpoint = usersMe;
  static const String aadhaarStartEndpoint = authAadhaarStart;
  static const String aadhaarVerifyEndpoint = authAadhaarVerify;
  static const String digilockerStartEndpoint = authDigilockerStart;
  static const String cropsEndpoint = crops;
  static const String ondcCatalogEndpoint = ondcCropListings;
  static const String marketPricesEndpoint = marketPrices;
  static const String predictEndpoint = predict;
  static const String logisticsProvidersEndpoint = logisticsProviders;
  static const String logisticsQuotesEndpoint = logisticsQuotes;
  static const String matchBackhaulsEndpoint = matchBackhauls;
  static const String statsEndpoint = stats;
  static const String transactionsEndpoint = transactions;
  static const String historyEndpoint = history;
  static const String healthEndpoint = health;
}
