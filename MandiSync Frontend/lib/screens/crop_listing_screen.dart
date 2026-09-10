// =========================================================
// MANDISYNC FLUTTER — CROP LISTING SCREEN (SELL CROPS)
// =========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CropListingScreen extends StatefulWidget {
  const CropListingScreen({super.key});

  @override
  State<CropListingScreen> createState() => _CropListingScreenState();
}

class _CropListingScreenState extends State<CropListingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _cropCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _farmerCtrl = TextEditingController();

  String _category = "Vegetables";
  String _unit = "quintal";
  final String _status = "active";

  bool _isSubmitting = false;
  CropListingModel? _lastCreated;

  // Active Listings State
  List<CropListingModel> _myListings = [];
  bool _isLoadingListings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = _api.currentUser;
    if (user != null) {
      _farmerCtrl.text = user.fullName;
    }
    _loadMyListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cropCtrl.dispose();
    _varietyCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _farmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyListings() async {
    setState(() => _isLoadingListings = true);
    try {
      final list = await _api.getCrops();
      if (mounted) {
        setState(() {
          _myListings = list;
          _isLoadingListings = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingListings = false);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _lastCreated = null;
    });

    final payload = {
      'crop_name': _cropCtrl.text.trim(),
      'commodity': _cropCtrl.text.trim(),
      'variety': _varietyCtrl.text.trim().isNotEmpty ? _varietyCtrl.text.trim() : null,
      'category': _category,
      'quantity': double.tryParse(_quantityCtrl.text) ?? 0.0,
      'unit': _unit,
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'location': _locationCtrl.text.trim(),
      'district': _districtCtrl.text.trim().isNotEmpty ? _districtCtrl.text.trim() : null,
      'state': _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
      'farmer_name': _farmerCtrl.text.trim().isNotEmpty ? _farmerCtrl.text.trim() : null,
      'status': _status,
    };

    try {
      final created = await _api.createCropListing(payload);
      if (mounted) {
        setState(() {
          _lastCreated = created;
          _isSubmitting = false;
        });
        _loadMyListings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Crop listing published to ONDC network!"), backgroundColor: Color(0xFF0B7A4B)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteListing(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Withdraw Listing?"),
        content: const Text("Are you sure you want to remove this harvest listing from the public marketplace?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Withdraw"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteCropListing(id);
        _loadMyListings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing withdrawn.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  String _money(double? val) {
    if (val == null) return "—";
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell Crops (Farmer Marketplace)"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.post_add), text: "Post Crop"),
            Tab(icon: Icon(Icons.inventory_2), text: "My Harvests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostFormTab(),
          _buildMyListingsTab(),
        ],
      ),
    );
  }

  Widget _buildPostFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Create Crop Harvest Listing",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
                ),
                const SizedBox(height: 4),
                Text(
                  "ONDC Beckn compliant format · Sent to /api/v1/crops",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cropCtrl,
                  decoration: const InputDecoration(labelText: "Crop Name *", hintText: "e.g. Tomato, Wheat, Potato"),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _varietyCtrl,
                  decoration: const InputDecoration(labelText: "Variety", hintText: "e.g. Hybrid, Sharbati, Desi"),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: "Category"),
                        items: ["Vegetables", "Cereals", "Pulses", "Fruits", "Oilseeds", "Spices"]
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: "Unit"),
                        items: ["quintal", "tonne", "kg", "crate", "bag"]
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Quantity *", hintText: "50"),
                        validator: (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Asking Price (₹/unit) *", hintText: "2400"),
                        validator: (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: "Farm / Village Location *", hintText: "e.g. Chomu Farm"),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtCtrl,
                        decoration: const InputDecoration(labelText: "District", hintText: "Jaipur"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(labelText: "State", hintText: "Rajasthan"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _farmerCtrl,
                  decoration: const InputDecoration(labelText: "Farmer Name", hintText: "Ramesh Kumar"),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitListing,
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: Text(_isSubmitting ? "Publishing..." : "🌾 Publish Harvest Listing"),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B7A4B), foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          if (_lastCreated != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "🎉 Harvest Listed Successfully",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF075B38)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                        child: const Text("ONDC Active", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Listing ID: ${_lastCreated!.id}", style: const TextStyle(fontSize: 12)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("AI Predicted Peak Price:"),
                      Text(
                        _money(_lastCreated!.aiPredictedMaxPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("AI Recommended MSP Floor:"),
                      Text(_money(_lastCreated!.aiRecommendedMsp), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyListingsTab() {
    if (_isLoadingListings) return const Center(child: CircularProgressIndicator());
    if (_myListings.isEmpty) {
      return const Center(child: Text("You haven't posted any crop listings yet."));
    }

    return RefreshIndicator(
      onRefresh: _loadMyListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myListings.length,
        itemBuilder: (context, i) {
          final c = _myListings[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_money(c.price), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0B7A4B))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("${c.quantity} ${c.unit} · ${c.location}"),
                  if (c.aiPredictedMaxPrice != null)
                    Text("AI Peak: ${_money(c.aiPredictedMaxPrice)}", style: const TextStyle(fontSize: 12, color: Color(0xFF0B7A4B))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(c.status, style: const TextStyle(fontSize: 11, color: Color(0xFF075B38))),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteListing(c.id),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text("Withdraw", style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
