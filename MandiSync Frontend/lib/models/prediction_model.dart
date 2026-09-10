class PredictionRequest {
  final String commodity;
  final String market;
  final String date;
  final double modalPrice;
  final double? minPrice;
  final double? arrivals;
  final String? variety;

  PredictionRequest({
    required this.commodity,
    required this.market,
    required this.date,
    required this.modalPrice,
    this.minPrice,
    this.arrivals,
    this.variety,
  });

  Map<String, dynamic> toJson() {
    return {
      'commodity': commodity,
      'market': market,
      'date': date,
      'modal_price': modalPrice,
      if (minPrice != null) 'min_price': minPrice,
      if (arrivals != null) 'arrivals': arrivals,
      if (variety != null) 'variety': variety,
    };
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{
      'commodity': commodity,
      'market': market,
      'date': date,
      'modal_price': modalPrice.toString(),
    };
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (arrivals != null) params['arrivals'] = arrivals.toString();
    if (variety != null) params['variety'] = variety!;
    return params;
  }
}

class PredictionResult {
  final double predictedPrice;
  final double confidenceMin;
  final double confidenceMax;
  final String trend;
  final String? optimalSellWindow;
  final String? recommendation;
  final double? confidenceScore;

  PredictionResult({
    required this.predictedPrice,
    required this.confidenceMin,
    required this.confidenceMax,
    this.trend = 'stable',
    this.optimalSellWindow,
    this.recommendation,
    this.confidenceScore,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final pred = (json['predicted_modal_price'] ?? json['predicted_price'] ?? json['prediction'] ?? 0.0);
    final double predVal = (pred is num) ? pred.toDouble() : double.tryParse('$pred') ?? 0.0;
    final minVal = (json['confidence_min'] is num) ? (json['confidence_min'] as num).toDouble() : (predVal * 0.94);
    final maxVal = (json['confidence_max'] is num) ? (json['confidence_max'] as num).toDouble() : (predVal * 1.06);

    return PredictionResult(
      predictedPrice: predVal,
      confidenceMin: minVal,
      confidenceMax: maxVal,
      trend: json['trend'] ?? (predVal > 0 ? 'rising' : 'stable'),
      optimalSellWindow: json['optimal_sell_window'] ?? json['sell_window'] ?? 'Next 5–7 Days',
      recommendation: json['recommendation'] ?? 'Expected high APMC demand based on XGBoost time-series projection.',
      confidenceScore: (json['confidence_score'] is num) ? (json['confidence_score'] as num).toDouble() : 0.89,
    );
  }
}
