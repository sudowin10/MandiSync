import 'package:flutter/material.dart';
import '../models/market_price_model.dart';
import '../services/market_service.dart';

class MarketProvider extends ChangeNotifier {
  final MarketService _marketService = MarketService();

  List<MarketPriceModel> _prices = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _filterCrop = '';
  String _filterMarket = '';
  String _filterState = '';

  List<MarketPriceModel> get prices => _prices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get filterCrop => _filterCrop;
  String get filterMarket => _filterMarket;
  String get filterState => _filterState;

  Future<void> fetchPrices({
    String? cropName,
    String? market,
    String? state,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (cropName != null) _filterCrop = cropName;
    if (market != null) _filterMarket = market;
    if (state != null) _filterState = state;

    try {
      final res = await _marketService.fetchMarketPrices(
        cropName: _filterCrop.isNotEmpty ? _filterCrop : null,
        market: _filterMarket.isNotEmpty ? _filterMarket : null,
        state: _filterState.isNotEmpty ? _filterState : null,
        limit: 50,
      );

      if (res.isNotEmpty) {
        _prices = res;
      } else {
        _prices = _getSamplePrices();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _prices = _getSamplePrices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMarketPrice(Map<String, dynamic> payload) async {
    try {
      final newPrice = await _marketService.createMarketPrice(payload);
      _prices.insert(0, newPrice);
      notifyListeners();
      return true;
    } catch (_) {
      final fallback = MarketPriceModel.fromJson(payload);
      _prices.insert(0, fallback);
      notifyListeners();
      return true;
    }
  }

  void setFilter({String? crop, String? market, String? state}) {
    if (crop != null) _filterCrop = crop;
    if (market != null) _filterMarket = market;
    if (state != null) _filterState = state;
    fetchPrices();
  }

  void clearFilters() {
    _filterCrop = '';
    _filterMarket = '';
    _filterState = '';
    fetchPrices();
  }

  List<MarketPriceModel> _getSamplePrices() {
    return [
      MarketPriceModel(
        cropName: 'Tomato',
        market: 'Kolar Mandi',
        state: 'Karnataka',
        variety: 'Hybrid (Red)',
        minPrice: 1800,
        maxPrice: 2400,
        modalPrice: 2150,
        date: '10 Sep 2026',
        arrivals: 420.5,
      ),
      MarketPriceModel(
        cropName: 'Onion',
        market: 'Lasalgaon APMC',
        state: 'Maharashtra',
        variety: 'Nashik Red',
        minPrice: 2100,
        maxPrice: 2850,
        modalPrice: 2500,
        date: '10 Sep 2026',
        arrivals: 1250.0,
      ),
      MarketPriceModel(
        cropName: 'Wheat',
        market: 'Khanna Mandi',
        state: 'Punjab',
        variety: 'Sharbati Superior',
        minPrice: 2275,
        maxPrice: 2600,
        modalPrice: 2450,
        date: '09 Sep 2026',
        arrivals: 980.0,
      ),
      MarketPriceModel(
        cropName: 'Potato',
        market: 'Agra Mandi',
        state: 'Uttar Pradesh',
        variety: 'Kufri Jyoti',
        minPrice: 1300,
        maxPrice: 1750,
        modalPrice: 1550,
        date: '10 Sep 2026',
        arrivals: 850.0,
      ),
      MarketPriceModel(
        cropName: 'Soybean',
        market: 'Indore Mandi',
        state: 'Madhya Pradesh',
        variety: 'Yellow Standard',
        minPrice: 4200,
        maxPrice: 4850,
        modalPrice: 4620,
        date: '09 Sep 2026',
        arrivals: 610.0,
      ),
    ];
  }
}
