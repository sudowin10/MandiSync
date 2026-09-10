// =========================================================
// MANDISYNC FLUTTER — STATS SCREEN
// =========================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _api = ApiService();
  DashboardStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final s = await _api.getStats();
    if (mounted) {
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    }
  }

  String _money(double val) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Market Stats & Analytics")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatTile("Total Sales Volume", _money(_stats?.totalSales ?? 15000), Icons.payments, const Color(0xFF0B7A4B)),
                  _buildStatTile("Active Orders", "${_stats?.activeOrders ?? 4}", Icons.pending_actions, const Color(0xFF0284C7)),
                  _buildStatTile("Total Crop Listings", "${_stats?.totalListings ?? 12}", Icons.inventory_2, const Color(0xFFF59E0B)),
                  _buildStatTile("Average Price Gain", _stats?.avgPriceImprovement ?? "+18.4%", Icons.trending_up, const Color(0xFF10B981)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
