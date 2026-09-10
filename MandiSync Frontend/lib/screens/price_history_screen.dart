// =========================================================
// MANDISYNC FLUTTER — PRICE HISTORY SCREEN
// Agmarknet Historical Mandi Price Records
// =========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PriceHistoryScreen extends StatefulWidget {
  final String? initialCommodity;
  const PriceHistoryScreen({super.key, this.initialCommodity});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  final ApiService _api = ApiService();
  List<MarketPriceModel> _prices = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _commodityFilterCtrl = TextEditingController();
  final TextEditingController _locationFilterCtrl = TextEditingController();
  String _selectedState = 'All';

  final List<String> _states = [
    'All',
    'Maharashtra',
    'Punjab',
    'Delhi',
    'Haryana',
    'Madhya Pradesh',
    'Uttar Pradesh',
    'Rajasthan'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCommodity != null) {
      _commodityFilterCtrl.text = widget.initialCommodity!;
    }
    _loadPriceHistory();
  }

  @override
  void dispose() {
    _commodityFilterCtrl.dispose();
    _locationFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPriceHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _api.getMarketPrices(
        cropName: _commodityFilterCtrl.text.trim().isNotEmpty ? _commodityFilterCtrl.text.trim() : null,
        market: _locationFilterCtrl.text.trim().isNotEmpty ? _locationFilterCtrl.text.trim() : null,
        state: _selectedState != 'All' ? _selectedState : null,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _prices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return "—";
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Mandi Price History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: _loadPriceHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPriceHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER INFO BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7EBD7)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0B7A4B),
                      radius: 20,
                      child: Icon(Icons.insights, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Agmarknet Historical Price Ledger",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF123B2A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Official daily arrivals, modal benchmarks, minimum and maximum trade prices across registered APMC Mandis.",
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // FILTER BAR
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _commodityFilterCtrl,
                          decoration: const InputDecoration(
                            labelText: "Commodity",
                            hintText: "e.g. Onion",
                            isDense: true,
                            prefixIcon: Icon(Icons.search, size: 18),
                          ),
                          onSubmitted: (_) => _loadPriceHistory(),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _locationFilterCtrl,
                          decoration: const InputDecoration(
                            labelText: "Mandi / City",
                            hintText: "e.g. Lasalgaon",
                            isDense: true,
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                          onSubmitted: (_) => _loadPriceHistory(),
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          decoration: const InputDecoration(labelText: "State", isDense: true),
                          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedState = v);
                              _loadPriceHistory();
                            }
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loadPriceHistory,
                        icon: const Icon(Icons.filter_alt, size: 16),
                        label: const Text("Apply Filter"),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SUMMARY STATS ROW
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile("Records Queried", "${_prices.length}", Icons.receipt_outlined, const Color(0xFF0B7A4B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile("Avg Modal Price", _computeAvgPrice(), Icons.currency_rupee, const Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile("Total Arrivals", _computeTotalArrivals(), Icons.scale_outlined, const Color(0xFFF59E0B)),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // PRICE HISTORY LIST / TABLE
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: Text("Error: $_error", style: const TextStyle(color: Colors.red)),
                )
              else if (_prices.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text("No historical records matching filter criteria.", style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Column(
                  children: _prices.map((p) => _buildPriceCard(p)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _computeAvgPrice() {
    if (_prices.isEmpty) return "—";
    final sum = _prices.fold<double>(0, (acc, p) => acc + (p.modalPrice ?? 0));
    return _formatCurrency(sum / _prices.length);
  }

  String _computeTotalArrivals() {
    if (_prices.isEmpty) return "—";
    final sum = _prices.fold<double>(0, (acc, p) => acc + (p.arrivalTonnes ?? 0));
    return "${sum.toStringAsFixed(0)} MT";
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MarketPriceModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.grass, color: Color(0xFF0B7A4B), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.commodity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          "${p.variety ?? 'Standard'} · ${p.market}, ${p.state ?? ''}",
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_formatCurrency(p.modalPrice)}/Qtl",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF0B7A4B)),
                    ),
                    Text(
                      "Modal Benchmark",
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPricePill("Min Price", _formatCurrency(p.minPrice), Colors.blueGrey),
                _buildPricePill("Max Price", _formatCurrency(p.maxPrice), const Color(0xFF075B38)),
                _buildPricePill("Arrival Volume", "${p.arrivalTonnes?.toStringAsFixed(0) ?? '—'} MT", const Color(0xFFF59E0B)),
                _buildPricePill("Arrival Date", p.arrivalDate ?? "Recent", Colors.grey[700]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricePill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
