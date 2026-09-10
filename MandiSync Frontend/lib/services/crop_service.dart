import '../constants/api_constants.dart';
import '../models/crop_model.dart';
import 'api_service.dart';

class CropService {
  final ApiService _api = ApiService();

  // ---------------------------------------------------------------------------
  // Section 2: Farmer Crop Listings (CRUD & ONDC Standardized)
  // ---------------------------------------------------------------------------

  /// GET /api/v1/crops - List/filter active crop listings
  Future<List<CropModel>> fetchCrops({
    String? commodity,
    String? location,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? skip,
  }) async {
    final query = <String, dynamic>{};
    if (commodity != null && commodity.isNotEmpty) query['commodity'] = commodity;
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (minPrice != null) query['min_price'] = minPrice;
    if (maxPrice != null) query['max_price'] = maxPrice;
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;

    final res = await _api.request(
      method: 'GET',
      path: ApiConstants.crops,
      queryParams: query,
    );

    List rawList = [];
    if (res is List) {
      rawList = res;
    } else if (res is Map) {
      rawList = res['items'] ?? res['data'] ?? [];
    }

    return rawList.map((item) => CropModel.fromJson(item)).toList();
  }

  /// POST /api/v1/crops - Create new crop listing (supports simple Farmer format or full ONDC Beckn schema)
  Future<CropModel> createCropListing(Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'POST',
      path: ApiConstants.crops,
      body: payload,
    );
    return CropModel.fromJson(res);
  }

  /// GET /api/v1/crops/{crop_id} - Retrieve single crop listing by ID
  Future<CropModel> getCropById(dynamic cropId) async {
    final res = await _api.request(
      method: 'GET',
      path: ApiConstants.cropById(cropId),
    );
    return CropModel.fromJson(res);
  }

  /// PUT /api/v1/crops/{crop_id} - Complete replacement of crop listing
  Future<CropModel> replaceCropListing(dynamic cropId, Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'PUT',
      path: ApiConstants.cropById(cropId),
      body: payload,
    );
    return CropModel.fromJson(res);
  }

  /// PATCH /api/v1/crops/{crop_id} - Partial update of crop listing (price, quantity, status, grade)
  Future<CropModel> updateCropListing(dynamic cropId, Map<String, dynamic> payload) async {
    final res = await _api.request(
      method: 'PATCH',
      path: ApiConstants.cropById(cropId),
      body: payload,
    );
    return CropModel.fromJson(res);
  }

  /// DELETE /api/v1/crops/{crop_id} - Delete / withdraw crop listing
  Future<void> deleteCropListing(dynamic cropId) async {
    await _api.request(
      method: 'DELETE',
      path: ApiConstants.cropById(cropId),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 6: ONDC Beckn Protocol Webhooks & Catalog
  // ---------------------------------------------------------------------------

  /// GET /api/v1/ondc/crop_listings - Retrieve published ONDC catalog listings
  Future<List<CropModel>> fetchOndcCatalog() async {
    try {
      final res = await _api.request(
        method: 'GET',
        path: ApiConstants.ondcCropListings,
      );
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['items'] ?? res['data'] ?? [];
      }
      return rawList.map((item) => CropModel.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  /// POST /api/v1/ondc/crop_listings - Publish new crop listing directly to ONDC network catalog
  Future<dynamic> publishOndcCropListing(Map<String, dynamic> payload) async {
    return await _api.request(
      method: 'POST',
      path: ApiConstants.ondcCropListings,
      body: payload,
    );
  }

  /// GET /api/v1/ondc/crop_listings/{item_id} - Get specific ONDC catalog listing by Beckn Item SKU
  Future<dynamic> getOndcCropListingById(dynamic itemId) async {
    return await _api.request(
      method: 'GET',
      path: ApiConstants.ondcCropListingById(itemId),
    );
  }

  /// POST /api/v1/ondc/search - ONDC discovery webhook receiving search requests from Buyer Apps (BAP)
  Future<dynamic> ondcSearch(Map<String, dynamic> payload) async {
    return await _api.request(
      method: 'POST',
      path: ApiConstants.ondcSearch,
      body: payload,
    );
  }

  /// POST /api/v1/ondc/select - ONDC quotation / item selection webhook returning structured quote
  Future<dynamic> ondcSelect(Map<String, dynamic> payload) async {
    return await _api.request(
      method: 'POST',
      path: ApiConstants.ondcSelect,
      body: payload,
    );
  }
}
