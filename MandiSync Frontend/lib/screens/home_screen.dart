// =========================================================
// MANDISYNC FLUTTER — HOME SCREEN
// Matches Reference Image Screen 1 Exactly
// =========================================================

import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO SECTION
          Container(
            color: const Color(0xFFF6F9F7),
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 3, child: _buildHeroText()),
                          const SizedBox(width: 36),
                          Expanded(flex: 2, child: _buildHeroGraphic()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroText(),
                          const SizedBox(height: 24),
                          _buildHeroGraphic(),
                        ],
                      ),
              ),
            ),
          ),

          // 2. MAIN CONTENT WRAPPER
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4 Feature Cards Grid
                    _buildFeatureCardsGrid(isDesktop),

                    const SizedBox(height: 36),

                    // Key Statistics
                    _buildKeyStatisticsHeader(),
                    const SizedBox(height: 14),
                    _buildKeyStatisticsCards(isDesktop),

                    const SizedBox(height: 36),

                    // Recent Market Prices Table
                    _buildRecentPricesHeader(),
                    const SizedBox(height: 14),
                    _buildRecentPricesTable(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // 3. DARK NAVY GOVERNMENT FOOTER
          _buildFooter(isDesktop),
        ],
      ),
    );
  }

  // --- HERO COMPONENTS ---
  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Connecting Farmers\nto a Stronger Market",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Color(0xFF123B2A),
            height: 1.18,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "An open, digital marketplace powered by ONDC,\nAI and data — for better prices, fair trade and\nsustainable agriculture.",
          style: TextStyle(
            fontSize: 14.5,
            color: Colors.grey[700],
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () => widget.onNavigate(1), // Markets tab
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B7A4B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Explore Markets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroGraphic() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF86EFAC), Color(0xFF16A34A), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background lush agricultural pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(painter: _FieldPatternPainter()),
              ),
            ),
          ),

          // Central Visual representation
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_android, size: 44, color: Color(0xFF0B7A4B)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🌾 MandiSync AgTech Engine",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF123B2A)),
                  ),
                ),
              ],
            ),
          ),

          // Floating Badges from Reference
          Positioned(
            top: 18,
            left: 20,
            child: _buildFloatingBadge("🌿", "Agmarknet"),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: _buildFloatingBadge("📈", "AI Forecast"),
          ),
          Positioned(
            bottom: 20,
            right: 30,
            child: _buildFloatingBadge("🚚", "Logistics"),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF123B2A))),
        ],
      ),
    );
  }

  // --- 4 FEATURE CARDS GRID ---
  Widget _buildFeatureCardsGrid(bool isDesktop) {
    final cards = [
      _buildFeatureCard(
        icon: Icons.storefront_outlined,
        iconColor: const Color(0xFF0B7A4B),
        title: "Live Mandi Prices",
        desc: "Real-time market\nrates across India",
        onTap: () => widget.onNavigate(1),
      ),
      _buildFeatureCard(
        icon: Icons.trending_up,
        iconColor: const Color(0xFF0284C7),
        title: "AI Price Forecast",
        desc: "Predicts price trends\n(7 days ahead)",
        onTap: () => widget.onNavigate(3),
      ),
      _buildFeatureCard(
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFF10B981),
        title: "Smart Logistics",
        desc: "Optimized shared\ntransport routes",
        onTap: () => widget.onNavigate(4),
      ),
      _buildFeatureCard(
        icon: Icons.handshake_outlined,
        iconColor: const Color(0xFF0B7A4B),
        title: "Reverse Auction",
        desc: "Bulk buyers to\nfarmers directly",
        onTap: () => widget.onNavigate(2),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
      );
    }
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDFE7E2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF123B2A))),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 11.5, height: 1.3)),
          ],
        ),
      ),
    );
  }

  // --- KEY STATISTICS ---
  Widget _buildKeyStatisticsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Key Statistics",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF123B2A)),
        ),
        InkWell(
          onTap: () => widget.onNavigate(1),
          child: const Row(
            children: [
              Text("View Detailed Report", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B))),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0B7A4B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyStatisticsCards(bool isDesktop) {
    final stats = [
      _buildStatBox("12,480+", "Registered Farmers & FPOs", Icons.domain, const Color(0xFF0B7A4B)),
      _buildStatBox("320+", "Active Buyers", Icons.inventory_2_outlined, const Color(0xFF0284C7)),
      _buildStatBox("1,250+", "MT Trade Volume (Today)", Icons.water_drop_outlined, const Color(0xFF0284C7)),
      _buildStatBox("18%", "Avg. Price Improvement", Icons.pie_chart_outline, const Color(0xFF10B981)),
    ];

    if (isDesktop) {
      return Row(
        children: stats.map((s) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: s))).toList(),
      );
    } else {
      return Column(
        children: stats.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: s)).toList(),
      );
    }
  }

  Widget _buildStatBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- RECENT MARKET PRICES TABLE ---
  Widget _buildRecentPricesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Market Prices",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF123B2A)),
        ),
        InkWell(
          onTap: () => widget.onNavigate(1),
          child: const Row(
            children: [
              Text("View All", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B))),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0B7A4B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPricesTable() {
    // Default matching reference picture exactly:
    // Wheat: 2,350 | +2.4% | green
    // Paddy: 2,180 | +1.8% | green
    // Tomato: 1,200 | -3.2% | red
    // Onion: 1,560 | +0.6% | green
    // Potato: 1,320 | -1.1% | red
    final rows = [
      {"icon": "🌾", "name": "Wheat", "price": "2,350", "change": "+2.4%", "isUp": true},
      {"icon": "🌱", "name": "Paddy", "price": "2,180", "change": "+1.8%", "isUp": true},
      {"icon": "🍅", "name": "Tomato", "price": "1,200", "change": "-3.2%", "isUp": false},
      {"icon": "🧅", "name": "Onion", "price": "1,560", "change": "+0.6%", "isUp": true},
      {"icon": "🥔", "name": "Potato", "price": "1,320", "change": "-1.1%", "isUp": false},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFDFE7E2))),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text("Commodity", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const Expanded(flex: 3, child: Text("Current Price (₹/Quintal)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const Expanded(flex: 2, child: Text("Change (24h)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                const Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("Trend", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))))),
              ],
            ),
          ),

          // Table Rows
          ...rows.map((r) {
            final isUp = r['isUp'] as bool;
            final color = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Text(r['icon'] as String, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF123B2A))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r['price'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF123B2A)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      r['change'] as String,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 55,
                        height: 20,
                        child: CustomPaint(painter: _SparklinePainter(isUp: isUp)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- DARK GOVERNMENT FOOTER ---
  Widget _buildFooter(bool isDesktop) {
    return Container(
      color: const Color(0xFF102837), // Dark navy government footer
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFooterLeft(),
                    _buildFooterRight(),
                  ],
                )
              : Column(
                  children: [
                    _buildFooterLeft(),
                    const SizedBox(height: 16),
                    _buildFooterRight(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooterLeft() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("🏛️", style: TextStyle(fontSize: 20)),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Government of India", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
            Text("Ministry of Agriculture & Farmers Welfare", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterRight() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Privacy Policy", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Text("   |   ", style: TextStyle(color: Color(0xFF475569))),
        Text("Terms of Service", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Text("   |   ", style: TextStyle(color: Color(0xFF475569))),
        Text("Contact Us", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final bool isUp;
  _SparklinePainter({required this.isUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height * 0.75);
      path.quadraticBezierTo(size.width * 0.35, size.height * 0.8, size.width * 0.5, size.height * 0.45);
      path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    } else {
      path.moveTo(0, size.height * 0.2);
      path.quadraticBezierTo(size.width * 0.35, size.height * 0.3, size.width * 0.5, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.75, size.height * 0.5, size.width, size.height * 0.85);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.isUp != isUp;
}

class _FieldPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (double i = -size.width; i < size.width * 2; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPatternPainter oldDelegate) => false;
}
