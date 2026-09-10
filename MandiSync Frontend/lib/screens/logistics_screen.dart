import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/logistics_model.dart';
import '../providers/logistics_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _originCtrl = TextEditingController(text: 'Nashik APMC, Maharashtra');
  final _destCtrl = TextEditingController(text: 'Azadpur Mandi, Delhi');
  final _weightCtrl = TextEditingController(text: '8000');
  final _commodityCtrl = TextEditingController(text: 'Tomato & Onion');
  String _vehicleType = 'Medium Truck (10 Ton)';
  bool _returnEmptyDiscount = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogisticsProvider>().fetchProviders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _weightCtrl.dispose();
    _commodityCtrl.dispose();
    super.dispose();
  }

  void _showBackhaulMatchDialog(String providerId) async {
    final logProv = context.read<LogisticsProvider>();
    await logProv.matchBackhauls(providerId);
    final match = logProv.backhaulMatch;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('🔄 ', style: TextStyle(fontSize: 20)),
            Text('Backhaul Match: $providerId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.subtleGreen, borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'Empty return run identified! Guaranteed 20–40% freight discount applied automatically.',
                style: TextStyle(fontSize: 13, color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text('Route: ${match?['empty_backhaul_route'] ?? "Azadpur -> Jaipur APMC"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Text('Savings: ${match?['estimated_freight_savings'] ?? "32% Discount"}', style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Recommended Cargo: ${match?['matched_crop'] ?? "Tomato / Vegetables"}', style: const TextStyle(fontSize: 12.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(backgroundColor: AppTheme.primaryGreen, content: Text('Backhaul cargo hold reserved for this transport!')),
              );
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  void _showRegisterProviderDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Transport Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Transporter / Fleet Name *')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Phone *')),
              const SizedBox(height: 10),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Base / Current Location *')),
              const SizedBox(height: 10),
              TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity (Kg) *')),
              const SizedBox(height: 10),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tariff (₹ / Km) *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || locCtrl.text.isEmpty) return;
              final payload = {
                'provider_id': 'TRK-REG-${DateTime.now().millisecondsSinceEpoch % 10000}',
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'vehicle_type': 'Medium Truck (10 Ton)',
                'capacity_kg': double.tryParse(capCtrl.text.trim()) ?? 10000,
                'current_location': locCtrl.text.trim(),
                'status': 'available',
                'cost_per_km': double.tryParse(costCtrl.text.trim()) ?? 25.0,
              };
              await context.read<LogisticsProvider>().registerProvider(payload);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle registered to MandiSync Fleet!')),
                );
              }
            },
            child: const Text('Register Vehicle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MandiAppBar(title: 'Fleet & Smart Backhauls'),
      drawer: const AppNavDrawer(activeRoute: '/logistics'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.saffron,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_shipping),
        label: const Text('Register Vehicle'),
        onPressed: _showRegisterProviderDialog,
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
                Tab(text: '💰 Quote Calculator'),
                Tab(text: '🚛 Available Fleet'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuoteCalculatorTab(context),
                _buildFleetDirectoryTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCalculatorTab(BuildContext context) {
    final logProv = context.watch<LogisticsProvider>();
    final quote = logProv.quoteResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trip Freight Quote Calculator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Save 20–40% on backhaul return legs', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const Divider(height: 24),
                  TextField(controller: _originCtrl, decoration: const InputDecoration(labelText: 'Pickup Location / Mandi *')),
                  const SizedBox(height: 12),
                  TextField(controller: _destCtrl, decoration: const InputDecoration(labelText: 'Destination Mandi *')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (Kg) *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _commodityCtrl, decoration: const InputDecoration(labelText: 'Commodity'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _vehicleType,
                    decoration: const InputDecoration(labelText: 'Vehicle Type'),
                    items: ['Pickup Truck (2 Ton)', 'Medium Truck (10 Ton)', 'Heavy Truck (25 Ton)', 'Reefer Cold Chain (5 Ton)']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _vehicleType = v!),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _returnEmptyDiscount,
                    title: const Text('Apply Smart Backhaul Discount (20–40%)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Match with empty return trucks on this highway route', style: TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => setState(() => _returnEmptyDiscount = v ?? true),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: logProv.isLoading
                        ? null
                        : () {
                            final req = LogisticsQuoteRequest(
                              origin: _originCtrl.text.trim(),
                              destination: _destCtrl.text.trim(),
                              weightKg: double.tryParse(_weightCtrl.text.trim()) ?? 5000,
                              commodity: _commodityCtrl.text.trim(),
                              vehicleType: _vehicleType,
                              returnEmptyDiscount: _returnEmptyDiscount,
                            );
                            logProv.calculateQuote(req);
                          },
                    child: logProv.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Calculate Discounted Freight Quote'),
                  ),
                ],
              ),
            ),
          ),
          if (quote != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppTheme.subtleGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.borderGreen, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Freight Calculation', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text('Saved ₹${quote.discountAmount.toInt()} (${quote.discountPercent.toInt()}%)', style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('₹${quote.estimatedCost.toInt()}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryDark)),
                    Text('Standard Tariff: ₹${quote.baseCost.toInt()} (Distance: ~${quote.distanceKm.toInt()} km)', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    const Divider(height: 20),
                    const Text('✓ Matched with returning carrier on your transport corridor.', style: TextStyle(fontSize: 13, color: AppTheme.primaryDark, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFleetDirectoryTab(BuildContext context) {
    final logProv = context.watch<LogisticsProvider>();
    final providers = logProv.providers;

    return RefreshIndicator(
      onRefresh: () => logProv.fetchProviders(),
      child: providers.isEmpty
          ? const Center(child: Text('No transporters found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: providers.length,
              itemBuilder: (ctx, i) {
                final p = providers[i];
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
                              child: Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.status == 'empty_return' ? AppTheme.saffronLight : AppTheme.subtleGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.status == 'empty_return' ? 'Empty Return Backhaul' : 'Available',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: p.status == 'empty_return' ? AppTheme.saffron : AppTheme.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${p.vehicleType} · Capacity: ${(p.capacityKg / 1000).toStringAsFixed(1)} Tons', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        Text('Base: ${p.currentLocation}', style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tariff: ₹${p.costPerKm.toInt()} / km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                              icon: const Icon(Icons.sync, size: 16),
                              label: const Text('Match Backhaul', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showBackhaulMatchDialog(p.providerId),
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
