import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';

class CropProvider extends ChangeNotifier {
  final CropService _cropService = CropService();

  List<CropModel> _farmerCrops = [];
  List<CropModel> _ondcCatalog = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CropModel> get farmerCrops => _farmerCrops;
  List<CropModel> get ondcCatalog => _ondcCatalog;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final crops = await _cropService.fetchCrops();
      _farmerCrops = crops.isNotEmpty ? crops : _getSampleFarmerCrops();

      final ondc = await _cropService.fetchOndcCatalog();
      _ondcCatalog = ondc.isNotEmpty ? ondc : _getSampleOndcCatalog();
    } catch (e) {
      _errorMessage = e.toString();
      _farmerCrops = _getSampleFarmerCrops();
      _ondcCatalog = _getSampleOndcCatalog();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCrop(Map<String, dynamic> payload) async {
    try {
      final newCrop = await _cropService.createCropListing(payload);
      _farmerCrops.insert(0, newCrop);
      notifyListeners();
      return true;
    } catch (_) {
      final fallback = CropModel.fromJson({
        'id': DateTime.now().millisecondsSinceEpoch,
        ...payload,
      });
      _farmerCrops.insert(0, fallback);
      notifyListeners();
      return true;
    }
  }

  Future<bool> deleteCrop(dynamic cropId) async {
    try {
      await _cropService.deleteCropListing(cropId);
    } catch (_) {}
    _farmerCrops.removeWhere((item) => item.id == cropId);
    notifyListeners();
    return true;
  }

  List<CropModel> _getSampleFarmerCrops() {
    return [
      CropModel(
        id: 1,
        cropName: 'Tomato (Himsona)',
        commodity: 'Tomato',
        variety: 'Himsona Hybrid',
        category: 'Vegetables',
        quantity: 120,
        unit: 'Quintal',
        pricePerUnit: 2200,
        location: 'Kolar Mandi Yard',
        state: 'Karnataka',
        harvestDate: '2026-09-08',
        description: 'Naturally ripened, export grade A tomatoes packaged in plastic crates.',
        isOrganic: true,
        grade: 'Grade A',
        contactPhone: '+91 98450 12345',
        status: 'active',
      ),
      CropModel(
        id: 2,
        cropName: 'Wheat Sharbati',
        commodity: 'Wheat',
        variety: 'Sharbati Deluxe',
        category: 'Cereals',
        quantity: 350,
        unit: 'Quintal',
        pricePerUnit: 2650,
        location: 'Sehore Mandi',
        state: 'Madhya Pradesh',
        harvestDate: '2026-09-02',
        description: 'Golden high protein grain, sun dried with moisture under 10%.',
        isOrganic: false,
        grade: 'Premium',
        contactPhone: '+91 94250 56789',
        status: 'active',
      ),
      CropModel(
        id: 3,
        cropName: 'Red Onion (Nashik)',
        commodity: 'Onion',
        variety: 'Garwa Medium',
        category: 'Vegetables',
        quantity: 200,
        unit: 'Quintal',
        pricePerUnit: 2450,
        location: 'Lasalgaon Mandi',
        state: 'Maharashtra',
        harvestDate: '2026-09-05',
        description: 'Cured red onions, uniform 55mm+ size suitable for long transport.',
        isOrganic: false,
        grade: 'Standard',
        contactPhone: '+91 98220 98765',
        status: 'active',
      ),
    ];
  }

  List<CropModel> _getSampleOndcCatalog() {
    return [
      CropModel(
        id: 'ONDC-CR-001',
        cropName: 'Basmati Rice Pusa 1121',
        commodity: 'Paddy / Rice',
        variety: 'Pusa 1121 Extra Long',
        category: 'Cereals',
        quantity: 500,
        unit: 'Quintal',
        pricePerUnit: 4800,
        location: 'Karnal Grain Hub',
        state: 'Haryana',
        description: 'ONDC Beckn verified lot. Certified pesticide residue compliant.',
        isOrganic: false,
        grade: 'Grade A+',
        status: 'ondc_listed',
      ),
      CropModel(
        id: 'ONDC-CR-002',
        cropName: 'Organic Alphonso Mango (Pulp)',
        commodity: 'Mango',
        variety: 'Ratnagiri Alphonso',
        category: 'Fruits',
        quantity: 80,
        unit: 'Quintal',
        pricePerUnit: 7500,
        location: 'Ratnagiri APMC',
        state: 'Maharashtra',
        description: 'GI Tagged Ratnagiri mangoes, FSSAI certified batch.',
        isOrganic: true,
        grade: 'GI Tagged',
        status: 'ondc_listed',
      ),
    ];
  }
}
