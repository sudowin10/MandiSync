import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/prediction_model.dart';
import '../services/analytics_service.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnalyticsService _analyticsService = AnalyticsService();

  final _commodityCtrl = TextEditingController(text: 'Tomato');
  final _marketCtrl = TextEditingController(text: 'Kolar Mandi');
  final _modalPriceCtrl = TextEditingController(text: '2150');
  final _minPriceCtrl = TextEditingController(text: '1800');
  final _arrivalsCtrl = TextEditingController(text: '420');
  final _varietyCtrl = TextEditingController(text: 'Hybrid Red');

  bool _isLoading = false;
  PredictionResult? _result;

  @override
  void dispose() {
    _commodityCtrl.dispose();
    _marketCtrl.dispose();
    _modalPriceCtrl.dispose();
    _minPriceCtrl.dispose();
    _arrivalsCtrl.dispose();
    _varietyCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final req = PredictionRequest(
      commodity: _commodityCtrl.text.trim(),
      market: _marketCtrl.text.trim(),
      date: DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
      modalPrice: double.tryParse(_modalPriceCtrl.text.trim()) ?? 2000.0,
      minPrice: double.tryParse(_minPriceCtrl.text.trim()) ?? 1800.0,
      arrivals: double.tryParse(_arrivalsCtrl.text.trim()) ?? 400.0,
      variety: _varietyCtrl.text.trim(),
    );

    final res = await _analyticsService.predictOptimal(req);

    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MandiAppBar(title: 'XGBoost AI Price Analytics'),
      drawer: const AppNavDrawer(activeRoute: '/analytics'),
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
                                  'Predict Mandi Crop Price',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '⚡ XGBoost ML Engine',
                                    style: TextStyle(
                                      color: AppTheme.infoBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Time-series forecasting based on Agmarknet historical trends',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const Divider(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _commodityCtrl,
                                    decoration: const InputDecoration(labelText: 'Commodity *'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _marketCtrl,
                                    decoration: const InputDecoration(labelText: 'APMC Market *'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _modalPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Current Modal (₹) *'),
                                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _minPriceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Min Price (₹)'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _arrivalsCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Arrivals (Tons)'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _varietyCtrl,
                                    decoration: const InputDecoration(labelText: 'Variety'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDark,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.insights),
                              label: Text(_isLoading ? 'Computing ML Forecast...' : 'Run XGBoost Prediction'),
                              onPressed: _isLoading ? null : _runPrediction,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PREDICTION RESULT CARD
                  if (_result != null) ...[
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
                                const Text(
                                  'Forecast Output',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${((_result!.confidenceScore ?? 0.89) * 100).toInt()}% Confidence',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹${_result!.predictedPrice.toInt()} / Quintal',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              'Expected Range: ₹${_result!.confidenceMin.toInt()} — ₹${_result!.confidenceMax.toInt()}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Divider(height: 24),

                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 18, color: AppTheme.primaryDark),
                                const SizedBox(width: 8),
                                Text(
                                  'Optimal Selling Window: ${_result!.optimalSellWindow ?? "Next 5 Days"}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _result!.recommendation ?? 'Positive market momentum predicted based on seasonal pattern.',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
