import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/market_price_model.dart';
import '../models/crop_model.dart';
import '../providers/market_provider.dart';
import '../providers/crop_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchPrices();
      context.read<CropProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPriceDialog() {
    final cropCtrl = TextEditingController();
    final marketCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final varietyCtrl = TextEditingController();
    final minPriceCtrl = TextEditingController();
    final maxPriceCtrl = TextEditingController();
    final modalPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Mandi Price Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop / Commodity *')),
              const SizedBox(height: 10),
              TextField(controller: marketCtrl, decoration: const InputDecoration(labelText: 'Market / Mandi *')),
              const SizedBox(height: 10),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State *')),
              const SizedBox(height: 10),
              TextField(controller: varietyCtrl, decoration: const InputDecoration(labelText: 'Variety')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: minPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min ₹'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: modalPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Modal ₹ *'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: maxPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max ₹'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (cropCtrl.text.isEmpty || marketCtrl.text.isEmpty || modalPriceCtrl.text.isEmpty) {
                return;
              }
              final payload = {
                'crop_name': cropCtrl.text.trim(),
                'market': marketCtrl.text.trim(),
                'state': stateCtrl.text.trim().isNotEmpty ? stateCtrl.text.trim() : 'National',
                'variety': varietyCtrl.text.trim(),
                'min_price': double.tryParse(minPriceCtrl.text) ?? double.tryParse(modalPriceCtrl.text) ?? 2000,
                'max_price': double.tryParse(maxPriceCtrl.text) ?? double.tryParse(modalPriceCtrl.text) ?? 2500,
                'modal_price': double.tryParse(modalPriceCtrl.text) ?? 2200,
                'date': DateTime.now().toIso8601String().substring(0, 10),
              };
              await context.read<MarketProvider>().addMarketPrice(payload);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mandi rate record added successfully!')),
                );
              }
            },
            child: const Text('Submit Record'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MandiAppBar(title: 'Markets & Mandi Prices'),
      drawer: const AppNavDrawer(activeRoute: '/markets'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Mandi Rate'),
        onPressed: _showAddPriceDialog,
      ),
      body: Column(
        children: [
          const GovBar(),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryDark,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryGreen,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '🏛️ APMC Mandi'),
                Tab(text: '🌾 Farmer Crops'),
                Tab(text: '🌐 ONDC Catalog'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApmcTab(context),
                _buildFarmerCropsTab(context),
                _buildOndcTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApmcTab(BuildContext context) {
    final marketProv = context.watch<MarketProvider>();
    final prices = marketProv.prices;

    return RefreshIndicator(
      onRefresh: () => marketProv.fetchPrices(),
      child: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Filter by Crop or Mandi...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onSubmitted: (val) {
                      marketProv.setFilter(crop: val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _searchController.clear();
                    marketProv.clearFilters();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: marketProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prices.isEmpty
                    ? const Center(child: Text('No mandi records found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: prices.length,
                        itemBuilder: (ctx, i) {
                          final item = prices[i];
                          return _buildMarketPriceCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketPriceCard(MarketPriceModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cropName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                    if (item.variety != null && item.variety!.isNotEmpty)
                      Text(item.variety!, style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.modalPrice.toInt()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                    ),
                    const Text('Modal / Qtl', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('${item.market}, ${item.state}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const Spacer(),
                Text(
                  'Range: ₹${item.minPrice.toInt()} – ₹${item.maxPrice.toInt()}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
                ),
              ],
            ),
            if (item.arrivals != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.subtleGreen, borderRadius: BorderRadius.circular(4)),
                    child: Text('Arrivals: ${item.arrivals!.toInt()} Tons', style: const TextStyle(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (item.date != null)
                    Text('Date: ${item.date}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerCropsTab(BuildContext context) {
    final cropProv = context.watch<CropProvider>();
    final crops = cropProv.farmerCrops;

    return RefreshIndicator(
      onRefresh: () => cropProv.fetchAll(),
      child: crops.isEmpty
          ? const Center(child: Text('No farmer crop listings yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: crops.length,
              itemBuilder: (ctx, i) {
                final crop = crops[i];
                return _buildCropCard(crop);
              },
            ),
    );
  }

  Widget _buildOndcTab(BuildContext context) {
    final cropProv = context.watch<CropProvider>();
    final ondcList = cropProv.ondcCatalog;

    return RefreshIndicator(
      onRefresh: () => cropProv.fetchAll(),
      child: ondcList.isEmpty
          ? const Center(child: Text('No ONDC Beckn items loaded.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ondcList.length,
              itemBuilder: (ctx, i) {
                final crop = ondcList[i];
                return _buildCropCard(crop, isOndc: true);
              },
            ),
    );
  }

  Widget _buildCropCard(CropModel crop, {bool isOndc = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(crop.cropName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                      Text('${crop.category ?? "Crop"} · ${crop.variety ?? "Standard"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOndc ? AppTheme.blueLight : AppTheme.subtleGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOndc ? 'ONDC Beckn' : 'Direct Farmer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOndc ? AppTheme.infoBlue : AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity: ${crop.quantity.toInt()} ${crop.unit}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.darkSlate),
                ),
                Text(
                  '₹${crop.pricePerUnit.toInt()} / ${crop.unit}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('${crop.location}${crop.state != null ? ", ${crop.state}" : ""}', style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
              ],
            ),
            if (crop.contactPhone != null && crop.contactPhone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 15, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  Text('Contact: ${crop.contactPhone}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
