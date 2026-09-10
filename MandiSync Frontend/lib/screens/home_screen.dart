import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../models/market_price_model.dart';
import '../providers/market_provider.dart';
import '../providers/crop_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchPrices();
      context.read<CropProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketProv = context.watch<MarketProvider>();
    final prices = marketProv.prices;

    return Scaffold(
      appBar: const MandiAppBar(),
      drawer: const AppNavDrawer(activeRoute: '/'),
      body: Column(
        children: [
          const GovBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HERO SECTION
                  _buildHeroSection(context, prices),

                  // CORE CAPABILITIES
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comprehensive Agriculture Intelligence',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Designed for farmers, traders, FPOs, and APMC market administrators.',
                          style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),

                        // FEATURE CARDS
                        _buildFeatureCard(
                          context,
                          icon: '₹',
                          title: 'Live Agmarknet Prices',
                          desc: 'Track real-time APMC market arrivals, minimum, maximum, and modal prices across India.',
                          route: '/markets',
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureCard(
                          context,
                          icon: '🤖',
                          title: 'XGBoost AI Forecast',
                          desc: 'Predict peak crop prices and optimal listing values with time-series machine learning.',
                          route: '/analytics',
                          color: AppTheme.infoBlue,
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureCard(
                          context,
                          icon: '🚚',
                          title: 'Smart Backhaul Logistics',
                          desc: 'Connect with returning-empty transport trucks for automated 20–40% freight discounts.',
                          route: '/logistics',
                          color: AppTheme.saffron,
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureCard(
                          context,
                          icon: '🌾',
                          title: 'ONDC Beckn Marketplace',
                          desc: 'Direct harvest listings compliant with open commerce protocol for verified nationwide buyers.',
                          route: '/crop-listing',
                          color: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ),

                  // CALL TO ACTION FOOTER
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to Sell Your Harvest at Best Rates?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'List your crops on the national network and access AI price guidance immediately.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryDark,
                          ),
                          onPressed: () => Navigator.pushNamed(context, '/crop-listing'),
                          child: const Text('List Produce Now →'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, List<MarketPriceModel> prices) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.subtleGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderGreen),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✨', style: TextStyle(fontSize: 12)),
                SizedBox(width: 6),
                Text(
                  'AI-Powered Agmarknet & ONDC Network',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connecting Farmers to a Stronger Market',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.darkSlate,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Discover real-time APMC mandi prices, run XGBoost AI price forecasts, list crops directly on ONDC Beckn, and save 20–40% on freight with smart return backhauls.',
            style: TextStyle(
              fontSize: 14.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // QUICK ACTION BUTTONS
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/markets'),
                child: const Text('Explore Mandi Prices →'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/analytics'),
                child: const Text('AI Price Forecast'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkSlate,
                  side: const BorderSide(color: AppTheme.borderSubtle),
                ),
                onPressed: () => Navigator.pushNamed(context, '/crop-listing'),
                child: const Text('List Your Crop'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // LIVE SNAPSHOT PREVIEW CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Market Snapshot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'APMC Feed',
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Agmarknet Daily APMC Market Arrivals',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const Divider(height: 24),
                if (prices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ...prices.take(3).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.cropName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                                Text(
                                  '${item.market} · ${item.state}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            Text(
                              '₹${item.modalPrice.toInt()} / Qtl',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String desc,
    required String route,
    required Color color,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
