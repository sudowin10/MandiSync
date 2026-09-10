// =========================================================
// MANDISYNC FLUTTER — XGBOOST PRICE FORECAST CHART WIDGET
// Custom Painter Rendering Dual-line Forecast with Confidence Band
// Matches Reference Image Screen 2 Exactly
// =========================================================

import 'package:flutter/material.dart';

class PricePoint {
  final String date;
  final double price;
  final bool isPredicted;
  final double? confLow;
  final double? confHigh;

  const PricePoint({
    required this.date,
    required this.price,
    required this.isPredicted,
    this.confLow,
    this.confHigh,
  });
}

class PriceForecastChart extends StatefulWidget {
  final String commodity;
  final double predictedPrice;
  final List<PricePoint>? customPoints;

  const PriceForecastChart({
    super.key,
    this.commodity = "Tomato",
    this.predictedPrice = 1850.0,
    this.customPoints,
  });

  @override
  State<PriceForecastChart> createState() => _PriceForecastChartState();
}

class _PriceForecastChartState extends State<PriceForecastChart> {
  int? _selectedIndex;

  List<PricePoint> _getPoints() {
    if (widget.customPoints != null && widget.customPoints!.isNotEmpty) {
      return widget.customPoints!;
    }
    // Default matching reference picture exactly: Tomato (₹/Quintal)
    // Apr 20 to Apr 22 historical; Apr 22 to Apr 26 predicted
    final p = widget.predictedPrice;
    return [
      const PricePoint(date: "Apr 20", price: 920, isPredicted: false),
      const PricePoint(date: "Apr 21", price: 1080, isPredicted: false),
      const PricePoint(date: "Apr 22", price: 1200, isPredicted: false),
      PricePoint(date: "Apr 23", price: 1420, isPredicted: true, confLow: 1300, confHigh: 1540),
      PricePoint(date: "Apr 24", price: 1580, isPredicted: true, confLow: 1420, confHigh: 1720),
      PricePoint(date: "Apr 25", price: 1720, isPredicted: true, confLow: 1530, confHigh: 1880),
      PricePoint(date: "Apr 26", price: p, isPredicted: true, confLow: p * 0.88, confHigh: p * 1.12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final points = _getPoints();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFE7E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price Forecast — ${widget.commodity} (₹/Quintal)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF123B2A),
                ),
              ),
              Row(
                children: [
                  _buildLegendItem("Historical", const Color(0xFF0284C7)),
                  const SizedBox(width: 16),
                  _buildLegendItem("Predicted", const Color(0xFF10B981)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart Canvas
          SizedBox(
            height: 230,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final dx = details.localPosition.dx;
                    final step = (constraints.maxWidth - 50) / (points.length - 1);
                    int idx = ((dx - 40) / step).round().clamp(0, points.length - 1);
                    setState(() => _selectedIndex = idx);
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 230),
                    painter: _ForecastChartPainter(
                      points: points,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Active Tooltip Info when selected
          if (_selectedIndex != null) ...[
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7EBD7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Date: ${points[_selectedIndex!].date} (${points[_selectedIndex!].isPredicted ? 'AI Forecast' : 'Actual Recorded'})",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF123B2A)),
                  ),
                  Text(
                    "₹${points[_selectedIndex!].price.toStringAsFixed(0)}/Qtl",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0B7A4B)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ForecastChartPainter extends CustomPainter {
  final List<PricePoint> points;
  final int? selectedIndex;

  _ForecastChartPainter({required this.points, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 40.0;
    const bottomMargin = 30.0;
    const topMargin = 35.0;
    final chartWidth = size.width - leftMargin - 15.0;
    final chartHeight = size.height - topMargin - bottomMargin;

    const minY = 600.0;
    const maxY = 2200.0;

    double getY(double price) {
      final normalized = (price - minY) / (maxY - minY);
      return size.height - bottomMargin - (normalized * chartHeight);
    }

    double getX(int index) {
      return leftMargin + (index * (chartWidth / (points.length - 1)));
    }

    // Grid lines & Y-axis labels: 800, 1200, 1600, 2000
    final gridPaint = Paint()
      ..color = const Color(0xFFE5ECE8)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(color: Colors.grey[500], fontSize: 10.5);

    final yValues = [800.0, 1200.0, 1600.0, 2000.0];
    for (final val in yValues) {
      final y = getY(val);
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - 15, y), gridPaint);

      final span = TextSpan(text: val.toInt().toString(), style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(5, y - (tp.height / 2)));
    }

    // X-axis labels
    for (int i = 0; i < points.length; i++) {
      final x = getX(i);
      final span = TextSpan(text: points[i].date, style: textStyle);
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), size.height - bottomMargin + 8));
    }

    // Find split index (where predicted begins)
    int splitIdx = points.indexWhere((p) => p.isPredicted);
    if (splitIdx == -1) splitIdx = points.length - 1;
    // To ensure continuity, transition point is splitIdx - 1
    int transitionIdx = (splitIdx > 0) ? splitIdx - 1 : 0;

    // 1. Shaded Confidence Interval Band (Apr 22 to Apr 26)
    final bandPath = Path();
    bandPath.moveTo(getX(transitionIdx), getY(points[transitionIdx].price));

    for (int i = transitionIdx; i < points.length; i++) {
      final x = getX(i);
      final high = points[i].confHigh ?? points[i].price * 1.08;
      bandPath.lineTo(x, getY(high));
    }

    for (int i = points.length - 1; i >= transitionIdx; i--) {
      final x = getX(i);
      final low = points[i].confLow ?? points[i].price * 0.92;
      bandPath.lineTo(x, getY(low));
    }
    bandPath.close();

    final bandPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // 2. Historical Line (Blue)
    final histPath = Path();
    histPath.moveTo(getX(0), getY(points[0].price));
    for (int i = 1; i <= splitIdx; i++) {
      histPath.lineTo(getX(i), getY(points[i].price));
    }

    final histPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(histPath, histPaint);

    // 3. Predicted Line (Green)
    final predPath = Path();
    predPath.moveTo(getX(transitionIdx), getY(points[transitionIdx].price));
    for (int i = splitIdx; i < points.length; i++) {
      predPath.lineTo(getX(i), getY(points[i].price));
    }

    final predPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(predPath, predPaint);

    // 4. Draw data points circles
    for (int i = 0; i < points.length; i++) {
      final x = getX(i);
      final y = getY(points[i].price);
      final color = points[i].isPredicted ? const Color(0xFF10B981) : const Color(0xFF0284C7);

      // Outer ring
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = color);
    }

    // 5. Floating Badge at end of predicted curve: "Predicted Price ₹ 1,850"
    final lastIdx = points.length - 1;
    final endX = getX(lastIdx);
    final endY = getY(points[lastIdx].price);

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(endX - 38, endY - 24), width: 95, height: 32),
      const Radius.circular(6),
    );

    final badgePaint = Paint()..color = const Color(0xFF123B2A);
    canvas.drawRRect(badgeRRect, badgePaint);

    // Badge text
    const badgeSub = TextSpan(
      text: "Predicted Price\n",
      style: TextStyle(color: Color(0xFF94B5A5), fontSize: 8.5, height: 1.1),
    );
    final badgeVal = TextSpan(
      text: "₹ ${points[lastIdx].price.toInt()}",
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
    );

    final badgeTp = TextPainter(
      text: TextSpan(children: [badgeSub, badgeVal]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    badgeTp.layout();
    badgeTp.paint(canvas, Offset(endX - 38 - (badgeTp.width / 2), endY - 24 - (badgeTp.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _ForecastChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.points != points;
  }
}
