import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/stats_models.dart';
import '../services/stats_service.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();
  DashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final data = await _statsService.fetchStats();
    if (mounted) {
      setState(() {
        _stats = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MandiAppBar(title: 'Dashboard Stats'),
      drawer: const AppNavDrawer(activeRoute: '/stats'),
      body: Column(
        children: [
          const GovBar(),
          Expanded(
            child: _isLoading || _stats == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Farmer Performance Dashboard',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real-time metrics from mandi transactions and ONDC trade settlement',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 20),

                          // STATS GRID
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'Total Revenue',
                                  value: '₹${_stats!.totalSales.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                  icon: '💰',
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'Active Orders',
                                  value: '${_stats!.activeOrders}',
                                  icon: '📦',
                                  color: AppTheme.infoBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'Total Listings',
                                  value: '${_stats!.totalListings}',
                                  icon: '🌾',
                                  color: AppTheme.saffron,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'Price Gain',
                                  value: _stats!.avgPriceImprovement,
                                  icon: '📈',
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // PERFORMANCE HIGHLIGHT
                          Card(
                            color: AppTheme.subtleGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.borderGreen),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('🌟 ', style: TextStyle(fontSize: 20)),
                                      Text(
                                        'MandiSync AI Efficiency Benchmark',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'By utilizing XGBoost peak forecast timing and ONDC open network buyers, your produce reached an average of +18.4% above local APMC floor rates over the last 90 days.',
                                    style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                Text(icon, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
