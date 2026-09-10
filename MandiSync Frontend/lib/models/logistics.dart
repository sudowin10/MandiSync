class DeliveryQuoteRequest {
  final String origin;
  final String destination;
  final double weightKg;
  final double? distanceKm;
  final String? cropType;
  final String? preferredVehicleType;

  const DeliveryQuoteRequest({
    required this.origin,
    required this.destination,
    required this.weightKg,
    this.distanceKm,
    this.cropType,
    this.preferredVehicleType,
  });

  Map<String, dynamic> toJson() => {
    'origin': origin,
    'destination': destination,
    'weight_kg': weightKg,
    if (distanceKm != null) 'distance_km': distanceKm,
    if (cropType != null) 'crop_type': cropType,
    if (preferredVehicleType != null) 'preferred_vehicle_type': preferredVehicleType,
  };
}

class DeliveryQuoteResponse {
  final String quoteId;
  final String origin;
  final String destination;
  final double distanceKm;
  final double weightKg;
  final double estimatedCostInr;
  final bool isBackhaulDiscount;
  final double? backhaulDiscountPercent;
  final double? estimatedTransitHours;
  final String vehicleType;

  const DeliveryQuoteResponse({
    required this.quoteId,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.weightKg,
    required this.estimatedCostInr,
    required this.isBackhaulDiscount,
    this.backhaulDiscountPercent,
    this.estimatedTransitHours,
    required this.vehicleType,
  });

  factory DeliveryQuoteResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryQuoteResponse(
      quoteId: json['quote_id'] as String? ?? 'Q-0',
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
      estimatedCostInr: (json['estimated_cost_inr'] as num?)?.toDouble() ?? 0.0,
      isBackhaulDiscount: json['is_backhaul_discount'] as bool? ?? false,
      backhaulDiscountPercent: (json['backhaul_discount_percent'] as num?)?.toDouble(),
      estimatedTransitHours: (json['estimated_transit_hours'] as num?)?.toDouble(),
      vehicleType: json['vehicle_type'] as String? ?? 'LCV',
    );
  }
}

class LogisticsProvider {
  final String id;
  final String? name;
  final String? phone;
  final String homeBase;
  final String? currentLocation;
  final String status;
  final double perKmRateInr;
  final String? vehicleType;

  const LogisticsProvider({
    required this.id,
    this.name,
    this.phone,
    required this.homeBase,
    this.currentLocation,
    required this.status,
    required this.perKmRateInr,
    this.vehicleType,
  });

  factory LogisticsProvider.fromJson(Map<String, dynamic> json) {
    return LogisticsProvider(
      id: json['id'] as String? ?? json['provider_id'] as String? ?? '',
      name: json['name'] as String? ?? json['provider_name'] as String?,
      phone: json['phone'] as String?,
      homeBase: json['home_base'] as String? ?? '',
      currentLocation: json['current_location'] as String? ?? json['next_available_location'] as String?,
      status: json['status'] as String? ?? 'AVAILABLE',
      perKmRateInr: (json['per_km_rate_inr'] as num?)?.toDouble() ?? 20.0,
      vehicleType: json['vehicle_type'] as String? ?? (json['vehicle'] != null ? json['vehicle']['vehicle_type'] as String? : null),
    );
  }
}
