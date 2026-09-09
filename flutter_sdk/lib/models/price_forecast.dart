import 'package:fl_chart/fl_chart.dart';

class ForecastPoint {
  final int dayIndex;
  final String date;
  final String dayName;
  final double predictedPrice;
  final double confidenceLow;
  final double confidenceHigh;
  final double recommendedListingPrice;

  const ForecastPoint({
    required this.dayIndex,
    required this.date,
    required this.dayName,
    required this.predictedPrice,
    required this.confidenceLow,
    required this.confidenceHigh,
    required this.recommendedListingPrice,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      dayIndex: (json['day_index'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      dayName: json['day_name'] as String? ?? '',
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0.0,
      confidenceLow: (json['confidence_low'] as num?)?.toDouble() ?? 0.0,
      confidenceHigh: (json['confidence_high'] as num?)?.toDouble() ?? 0.0,
      recommendedListingPrice: (json['recommended_listing_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'day_index': dayIndex,
    'date': date,
    'day_name': dayName,
    'predicted_price': predictedPrice,
    'confidence_low': confidenceLow,
    'confidence_high': confidenceHigh,
    'recommended_listing_price': recommendedListingPrice,
  };

  /// Helper to convert directly to fl_chart FlSpot
  FlSpot toFlSpot() => FlSpot(dayIndex.toDouble(), predictedPrice);
  FlSpot toHighCiSpot() => FlSpot(dayIndex.toDouble(), confidenceHigh);
  FlSpot toLowCiSpot() => FlSpot(dayIndex.toDouble(), confidenceLow);
  FlSpot toFloorSpot() => FlSpot(dayIndex.toDouble(), recommendedListingPrice);
}

class PriceForecastResponse {
  final String status;
  final String commodity;
  final String market;
  final int days;
  final List<ForecastPoint> forecast;
  final String modelVersion;

  const PriceForecastResponse({
    required this.status,
    required this.commodity,
    required this.market,
    required this.days,
    required this.forecast,
    required this.modelVersion,
  });

  factory PriceForecastResponse.fromJson(Map<String, dynamic> json) {
    return PriceForecastResponse(
      status: json['status'] as String? ?? 'success',
      commodity: json['commodity'] as String? ?? '',
      market: json['market'] as String? ?? '',
      days: (json['days'] as num?)?.toInt() ?? 7,
      forecast: (json['forecast'] as List<dynamic>?)
              ?.map((e) => ForecastPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelVersion: json['model_version'] as String? ?? 'price_predictor_v1',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'commodity': commodity,
    'market': market,
    'days': days,
    'forecast': forecast.map((e) => e.toJson()).toList(),
    'model_version': modelVersion,
  };
}

class SinglePredictionResponse {
  final String status;
  final String commodity;
  final String market;
  final String targetDate;
  final double predictedMaxPrice;
  final double confidenceIntervalLow;
  final double confidenceIntervalHigh;
  final double recommendedListingPrice;
  final double inferenceLatencyMs;
  final String modelVersion;

  const SinglePredictionResponse({
    required this.status,
    required this.commodity,
    required this.market,
    required this.targetDate,
    required this.predictedMaxPrice,
    required this.confidenceIntervalLow,
    required this.confidenceIntervalHigh,
    required this.recommendedListingPrice,
    required this.inferenceLatencyMs,
    required this.modelVersion,
  });

  factory SinglePredictionResponse.fromJson(Map<String, dynamic> json) {
    return SinglePredictionResponse(
      status: json['status'] as String? ?? 'success',
      commodity: json['commodity'] as String? ?? '',
      market: json['market'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      predictedMaxPrice: (json['predicted_max_price'] as num?)?.toDouble() ?? 0.0,
      confidenceIntervalLow: (json['confidence_interval_low'] as num?)?.toDouble() ?? 0.0,
      confidenceIntervalHigh: (json['confidence_interval_high'] as num?)?.toDouble() ?? 0.0,
      recommendedListingPrice: (json['recommended_listing_price'] as num?)?.toDouble() ?? 0.0,
      inferenceLatencyMs: (json['inference_latency_ms'] as num?)?.toDouble() ?? 0.0,
      modelVersion: json['model_version'] as String? ?? 'price_predictor_v1',
    );
  }
}
