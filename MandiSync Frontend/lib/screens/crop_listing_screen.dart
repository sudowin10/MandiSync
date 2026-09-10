import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/crop_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class CropListingScreen extends StatefulWidget {
  const CropListingScreen({super.key});

  @override
  State<CropListingScreen> createState() => _CropListingScreenState();
}

class _CropListingScreenState extends State<CropListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cropNameCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'Vegetables';
  String _unit = 'Quintal';
  bool _isOrganic = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cropNameCtrl.dispose();
    _varietyCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _stateCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final payload = {
      'crop_name': _cropNameCtrl.text.trim(),
      'commodity': _cropNameCtrl.text.trim(),
      'variety': _varietyCtrl.text.trim(),
      'category': _category,
      'quantity': double.tryParse(_quantityCtrl.text.trim()) ?? 10.0,
      'unit': _unit,
      'price_per_unit': double.tryParse(_priceCtrl.text.trim()) ?? 1000.0,
      'location': _locationCtrl.text.trim(),
      'state': _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : 'India',
      'harvest_date': DateTime.now().toIso8601String().substring(0, 10),
      'description': _descCtrl.text.trim(),
      'is_organic': _isOrganic,
      'contact_phone': _phoneCtrl.text.trim(),
      'status': 'active',
    };

    final cropProv = context.read<CropProvider>();
    final success = await cropProv.createCrop(payload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _formKey.currentState!.reset();
        _cropNameCtrl.clear();
        _varietyCtrl.clear();
        _quantityCtrl.clear();
        _priceCtrl.clear();
        _locationCtrl.clear();
        _stateCtrl.clear();
        _phoneCtrl.clear();
        _descCtrl.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('Crop listing broadcasted to MandiSync & ONDC Network!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropProv = context.watch<CropProvider>();
    final myCrops = cropProv.farmerCrops;

    return Scaffold(
      appBar: const MandiAppBar(title: 'Sell Crops & ONDC Listing'),
      drawer: const AppNavDrawer(activeRoute: '/crop-listing'),
      body: Column(
        children: [
          const GovBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FORM CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Create New Crop Listing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.subtleGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ONDC Beckn',
                                    style: TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'ONDC Beckn Standardized Agricultural Catalog',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const Divider(height: 24),

                            TextFormField(
                              controller: _cropNameCtrl,
                              decoration: const InputDecoration(labelText: 'Crop / Commodity Name *', hintText: 'e.g. Tomato, Wheat, Potato'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Enter commodity name' : null,
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _varietyCtrl,
                                    decoration: const InputDecoration(labelText: 'Variety', hintText: 'e.g. Hybrid, Desi'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _category,
                                    decoration: const InputDecoration(labelText: 'Category'),
                                    items: ['Vegetables', 'Cereals', 'Fruits', 'Pulses', 'Oilseeds', 'Spices']
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _category = v!),
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
                                    decoration: const InputDecoration(labelText: 'Quantity *', hintText: '100'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _unit,
                                    decoration: const InputDecoration(labelText: 'Unit'),
                                    items: ['Quintal', 'Kg', 'Ton', 'Bag']
                                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _unit = v!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price per $_unit (₹) *',
                                hintText: 'e.g. 2400',
                                prefixText: '₹ ',
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _locationCtrl,
                                    decoration: const InputDecoration(labelText: 'Location / Mandi *', hintText: 'e.g. Nashik APMC'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateCtrl,
                                    decoration: const InputDecoration(labelText: 'State', hintText: 'e.g. Maharashtra'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Contact Phone *', hintText: '+91 98765 43210'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),

                            CheckboxListTile(
                              value: _isOrganic,
                              title: const Text('Organic Certified Produce', style: TextStyle(fontSize: 14)),
                              subtitle: const Text('Check if grown without chemical pesticides/fertilizers', style: TextStyle(fontSize: 12)),
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppTheme.primaryGreen,
                              onChanged: (v) => setState(() => _isOrganic = v ?? false),
                            ),
                            const SizedBox(height: 16),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Publish Crop Listing to ONDC'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Active Harvest Listings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 12),

                  if (myCrops.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No active crops listed. Fill the form above.')),
                      ),
                    )
                  else
                    ...myCrops.map((crop) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.subtleGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('🌾', style: TextStyle(fontSize: 24)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        crop.cropName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '${crop.quantity.toInt()} ${crop.unit} · ₹${crop.pricePerUnit.toInt()}/${crop.unit}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryDark,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${crop.location}${crop.state != null ? ", ${crop.state}" : ""}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                                  onPressed: () {
                                    if (crop.id != null) {
                                      cropProv.deleteCrop(crop.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
