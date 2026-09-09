import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/price_forecast.dart';
import '../models/market_price.dart';
import '../models/crop.dart';
import '../models/logistics.dart';
import '../models/user_auth.dart';
import '../models/farmer_listing.dart';
import '../models/transaction.dart';

class MandiSyncApiService {
  /// Base API URL. 
  /// - Use 'http://localhost:8000' for iOS Simulator / Web
  /// - Use 'http://10.0.2.2:8000' for Android Emulator
  /// - Use 'http://<YOUR_IP>:8000' for physical phones
  final String baseUrl;
  final http.Client _client;

  // Stored JWT access token for authenticated requests
  String? _authToken;

  MandiSyncApiService({
    this.baseUrl = 'http://localhost:8000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Sets the auth token for subsequent requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool isJson = true}) {
    final map = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) map['Content-Type'] = 'application/json';
    if (_authToken != null) map['Authorization'] = 'Bearer $_authToken';
    return map;
  }

  // =========================================================================
  // 1. User Authentication & Profile (Sign Up, Login, Me)
  // =========================================================================

  /// Register a new Farmer, Buyer, Trader, or Transporter
  Future<UserProfile> registerUser(UserRegisterRequest req) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/register');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } else {
      throw Exception('Registration failed: [${response.statusCode}] ${response.body}');
    }
  }

  /// Login with username & password to receive a JWT Token
  Future<AuthTokenResponse> loginUser(UserLoginRequest req) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      final tokenResp = AuthTokenResponse.fromJson(jsonMap);
      _authToken = tokenResp.accessToken; // Automatically cache token
      return tokenResp;
    } else {
      throw Exception('Login failed: [${response.statusCode}] ${response.body}');
    }
  }

  /// Get profile of the currently logged-in user
  Future<UserProfile> getCurrentUserProfile() async {
    final uri = Uri.parse('$baseUrl/api/v1/users/me');
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load profile: [${response.statusCode}] ${response.body}');
    }
  }

  // =========================================================================
  // 2. Farmer Crop Listings & Inventory
  // =========================================================================

  /// Post a new crop harvest for sale on MandiSync / ONDC network
  Future<FarmerListingResponse> createFarmerListing(CreateFarmerListingRequest req) async {
    final uri = Uri.parse('$baseUrl/api/v1/crops');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return FarmerListingResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to create harvest listing: [${response.statusCode}] ${response.body}');
    }
  }

  /// Fetch active farmer listings
  Future<List<FarmerListingResponse>> getFarmerListings({int limit = 50}) async {
    final uri = Uri.parse('$baseUrl/api/v1/crops/?limit=$limit');
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => FarmerListingResponse.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load listings: [${response.statusCode}] ${response.body}');
    }
  }

  // =========================================================================
  // 3. Transactions & Order History
  // =========================================================================

  /// Fetch user transaction & trade history
  Future<List<TransactionRecord>> getTransactions() async {
    final uri = Uri.parse('$baseUrl/api/v1/transactions');
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data is Map && data.containsKey('data')) ? data['data'] as List<dynamic> : (data as List<dynamic>);
      return list.map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  /// Get dashboard financial stats (Total sales, active orders, etc.)
  Future<DashboardStats> getDashboardStats() async {
    final uri = Uri.parse('$baseUrl/api/v1/stats');
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardStats.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load stats: [${response.statusCode}] ${response.body}');
    }
  }

  // =========================================================================
  // 4. Identity & KYC Verification (Aadhaar / DigiLocker)
  // =========================================================================

  Future<Map<String, dynamic>> startAadhaarKyc(String aadhaarNumber) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/aadhaar/start');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'aadhaar_number': aadhaarNumber}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to initiate Aadhaar OTP');
  }

  Future<Map<String, dynamic>> startDigilockerKyc(String mobileOrAadhaar) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/digilocker/start');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'identifier': mobileOrAadhaar}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to initiate DigiLocker Auth');
  }

  // =========================================================================
  // 5. AI Price Forecasting & 7-Day fl_chart Series
  // =========================================================================

  Future<PriceForecastResponse> getPriceForecast({
    required String commodity,
    required String market,
    int days = 7,
    double? modalPrice,
    double? minPrice,
    double? arrivals,
    String variety = 'Standard',
  }) async {
    final queryParams = {
      'commodity': commodity,
      'market': market,
      'days': days.toString(),
      if (modalPrice != null) 'modal_price': modalPrice.toString(),
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (arrivals != null) 'arrivals': arrivals.toString(),
      'variety': variety,
    };

    final uri = Uri.parse('$baseUrl/api/v1/predict/forecast').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return PriceForecastResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load forecast: [${response.statusCode}] ${response.body}');
    }
  }

  // =========================================================================
  // 6. Agmarknet Live Market Feed (309+ Atlas Records)
  // =========================================================================

  Future<List<AgmarknetPriceRecord>> getMarketPrices({
    String? cropName,
    String? location,
    String? state,
    int limit = 50,
    int skip = 0,
  }) async {
    final queryParams = {
      if (cropName != null && cropName.isNotEmpty) 'crop_name': cropName,
      if (location != null && location.isNotEmpty) 'location': location,
      if (state != null && state.isNotEmpty) 'state': state,
      'limit': limit.toString(),
      'skip': skip.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/v1/market-prices').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => AgmarknetPriceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load market prices: [${response.statusCode}] ${response.body}');
    }
  }

  // =========================================================================
  // 7. Logistics & Backhaul Quotes
  // =========================================================================

  Future<DeliveryQuoteResponse> requestDeliveryQuote(DeliveryQuoteRequest req) async {
    final uri = Uri.parse('$baseUrl/api/v1/logistics/quotes');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      return DeliveryQuoteResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to calculate quote: [${response.statusCode}] ${response.body}');
    }
  }

  Future<List<LogisticsProvider>> getLogisticsProviders({
    String? status,
    String? location,
    int limit = 30,
  }) async {
    final queryParams = {
      if (status != null) 'status': status,
      if (location != null) 'location': location,
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/api/v1/logistics/providers').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _headers(isJson: false));

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => LogisticsProvider.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load providers: [${response.statusCode}] ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
