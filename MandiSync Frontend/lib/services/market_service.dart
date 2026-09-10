import '../constants/api_constants.dart';
import '../models/market_price_model.dart';
import 'api_service.dart';

class MarketService {
  final ApiService _api = ApiService();

  // ---------------------------------------------------------------------------
  // Section 3: Agmarknet Historical Market Prices (CRUD)
  // ---------------------------------------------------------------------------

  /// GET /api/v1/market-prices - Query historical mandi price records with filters
  Future<List<MarketPriceModel>> fetchMarketPrices({
    String? cropName,
    String? market,
    String? state,
    String? variety,
    int? limit,
    int? skip,
  }) async {
    final query = <String, dynamic>{};
    if (cropName != null && cropName.isNotEmpty) query['crop_name'] = cropName;
    if (market != null && market.isNotEmpty) query['market'] = market;
    if (state != null && state.isNotEmpty) query['state'] = state;
    if (variety != null && variety.isNotEmpty) query['variety'] = variety;
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;

    final res = await _api.request(
      method: 'GET',
      path: ApiConstants.marketPrices,
      queryParams: query,
    );

    List rawList = [];
    if (res is List) {
      rawList = res;
    } else if (res is Map) {
      rawList = res['items'] ?? res['data'] ?? [];
    }

    return rawList.map((item) => MarketPriceModel.fromJson(item)).toList();
  }

  /// POST /api/v1/market-prices - Record new daily APMC mandi arrivals and min/max/modal prices
  Future<MarketPriceModel> createMarketPrice(Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'POST',
      path: ApiConstants.marketPrices,
      body: payload,
    );
    return MarketPriceModel.fromJson(res);
  }

  /// GET /api/v1/market-prices/{price_id} - Get specific market price entry by ID
  Future<MarketPriceModel> getMarketPriceById(dynamic priceId) async {
    final res = await _api.request(
      method: 'GET',
      path: ApiConstants.marketPriceById(priceId),
    );
    return MarketPriceModel.fromJson(res);
  }

  /// PUT /api/v1/market-prices/{price_id} - Replace market price entry
  Future<MarketPriceModel> replaceMarketPrice(dynamic priceId, Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'PUT',
      path: ApiConstants.marketPriceById(priceId),
      body: payload,
    );
    return MarketPriceModel.fromJson(res);
  }

  /// PATCH /api/v1/market-prices/{price_id} - Partial update for market price entry
  Future<MarketPriceModel> updateMarketPrice(dynamic priceId, Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'PATCH',
      path: ApiConstants.marketPriceById(priceId),
      body: payload,
    );
    return MarketPriceModel.fromJson(res);
  }

  /// DELETE /api/v1/market-prices/{price_id} - Delete market price entry
  Future<void> deleteMarketPrice(dynamic priceId) async {
    await _api.request(
      method: 'DELETE',
      path: ApiConstants.marketPriceById(priceId),
    );
  }
}
