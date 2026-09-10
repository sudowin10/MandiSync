// =========================================================
// MANDISYNC FLUTTER — MARKETS SCREEN
// =========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MarketsScreen extends StatefulWidget {
  final Function(int, {Map<String, String>? params})? onNavigateWithParams;

  const MarketsScreen({super.key, this.onNavigateWithParams});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  // Mandi Prices State
  List<MarketPriceModel> _mandiPrices = [];
  bool _isLoadingMandi = true;
  String? _mandiError;
  int _skip = 0;
  final int _limit = 25;

  // Filters
  final TextEditingController _cropFilterCtrl = TextEditingController();
  final TextEditingController _marketFilterCtrl = TextEditingController();
  final TextEditingController _stateFilterCtrl = TextEditingController();

  // Farmer Crops State
  List<CropListingModel> _farmerCrops = [];
  bool _isLoadingCrops = false;

  // ONDC State
  List<OndcItemModel> _ondcItems = [];
  bool _isLoadingOndc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _farmerCrops.isEmpty) _loadFarmerCrops();
      if (_tabController.index == 2 && _ondcItems.isEmpty) _loadOndcCatalog();
    });
    _loadMandiPrices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cropFilterCtrl.dispose();
    _marketFilterCtrl.dispose();
    _stateFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMandiPrices() async {
    setState(() {
      _isLoadingMandi = true;
      _mandiError = null;
    });

    try {
      final list = await _api.getMarketPrices(
        cropName: _cropFilterCtrl.text.trim(),
        market: _marketFilterCtrl.text.trim(),
        state: _stateFilterCtrl.text.trim(),
        limit: _limit,
        skip: _skip,
      );
      if (mounted) {
        setState(() {
          _mandiPrices = list;
          _isLoadingMandi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMandi = false;
        });
      }
    }
  }

  Future<void> _loadFarmerCrops() async {
    setState(() => _isLoadingCrops = true);
    try {
      final list = await _api.getCrops();
      if (mounted) {
        setState(() {
          _farmerCrops = list;
          _isLoadingCrops = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCrops = false);
    }
  }

  Future<void> _loadOndcCatalog() async {
    setState(() => _isLoadingOndc = true);
    try {
      final list = await _api.getOndcCatalog();
      if (mounted) {
        setState(() {
          _ondcItems = list;
          _isLoadingOndc = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOndc = false);
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
        title: const Text("Agricultural Markets & Mandis"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance), text: "APMC Mandis"),
            Tab(icon: Icon(Icons.grass), text: "Farmer Direct"),
            Tab(icon: Icon(Icons.language), text: "ONDC Beckn"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMandiPricesTab(),
          _buildFarmerCropsTab(),
          _buildOndcTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPriceDialog,
        icon: const Icon(Icons.add),
        label: const Text("Record Price"),
        backgroundColor: const Color(0xFF0B7A4B),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMandiPricesTab() {
    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cropFilterCtrl,
                      decoration: const InputDecoration(
                        hintText: "Crop (e.g. Tomato)",
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _marketFilterCtrl,
                      decoration: const InputDecoration(
                        hintText: "Mandi (e.g. Jaipur)",
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      _skip = 0;
                      _loadMandiPrices();
                    },
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mandi Prices List
        Expanded(
          child: _isLoadingMandi
              ? const Center(child: CircularProgressIndicator())
              : _mandiError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text("Error loading prices: $_mandiError", style: const TextStyle(color: Colors.red)),
                      ),
                    )
                  : _mandiPrices.isEmpty
                      ? const Center(child: Text("No records found for the filter criteria."))
                      : RefreshIndicator(
                          onRefresh: _loadMandiPrices,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _mandiPrices.length,
                            itemBuilder: (context, i) {
                              final p = _mandiPrices[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Color(0xFFDFE7E2)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            p.commodity,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            "${_money(p.modalPrice)}/Qtl",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Color(0xFF0B7A4B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Mandi: ${p.market} · State: ${p.state ?? '—'}",
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Min: ${_money(p.minPrice)} | Max: ${_money(p.maxPrice)}",
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                          OutlinedButton(
                                            onPressed: () {
                                              if (widget.onNavigateWithParams != null) {
                                                widget.onNavigateWithParams!(
                                                  3, // Analytics
                                                  params: {
                                                    'commodity': p.commodity,
                                                    'market': p.market,
                                                    'modal': p.modalPrice?.toString() ?? '',
                                                    'min': p.minPrice?.toString() ?? '',
                                                  },
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                            ),
                                            child: const Text("AI Forecast"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),

        // Pagination Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Page ${(_skip / _limit).floor() + 1}", style: const TextStyle(fontSize: 12)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _skip >= _limit
                        ? () {
                            setState(() => _skip -= _limit);
                            _loadMandiPrices();
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() => _skip += _limit);
                      _loadMandiPrices();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerCropsTab() {
    if (_isLoadingCrops) return const Center(child: CircularProgressIndicator());
    if (_farmerCrops.isEmpty) {
      return const Center(child: Text("No direct farmer listings active currently."));
    }

    return RefreshIndicator(
      onRefresh: _loadFarmerCrops,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _farmerCrops.length,
        itemBuilder: (context, i) {
          final c = _farmerCrops[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(c.cropName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "${c.quantity} ${c.unit} · ${c.location}\nFarmer: ${c.farmerName ?? 'Verified Farmer'}",
                style: const TextStyle(height: 1.3),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(c.price), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0B7A4B))),
                  if (c.aiPredictedMaxPrice != null)
                    Text("AI Max: ${_money(c.aiPredictedMaxPrice)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOndcTab() {
    if (_isLoadingOndc) return const Center(child: CircularProgressIndicator());
    if (_ondcItems.isEmpty) {
      return const Center(child: Text("No ONDC catalog items published yet."));
    }

    return RefreshIndicator(
      onRefresh: _loadOndcCatalog,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _ondcItems.length,
        itemBuilder: (context, i) {
          final item = _ondcItems[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.verified, color: Color(0xFF0284C7)),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("SKU: ${item.itemId} · Category: ${item.category}"),
              trailing: Text(_money(item.price), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  void _showAddPriceDialog() {
    final cropCtrl = TextEditingController();
    final marketCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final modalCtrl = TextEditingController();
    final maxCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Record APMC Mandi Price"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: "Commodity *")),
                TextField(controller: marketCtrl, decoration: const InputDecoration(labelText: "Market Mandi *")),
                TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: "State")),
                TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Min Price (₹) *")),
                TextField(controller: modalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Modal Price (₹) *")),
                TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Max Price (₹) *")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (cropCtrl.text.isEmpty || marketCtrl.text.isEmpty || modalCtrl.text.isEmpty) return;
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _api.createMarketPrice({
                    'commodity': cropCtrl.text.trim(),
                    'market': marketCtrl.text.trim(),
                    'state': stateCtrl.text.trim(),
                    'min_price': double.tryParse(minCtrl.text) ?? 0,
                    'modal_price': double.tryParse(modalCtrl.text) ?? 0,
                    'max_price': double.tryParse(maxCtrl.text) ?? 0,
                  });
                  nav.pop();
                  _loadMandiPrices();
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Mandi price recorded successfully!")),
                  );
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
