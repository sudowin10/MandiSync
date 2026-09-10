class TransportProvider {
  final dynamic id;
  final String providerId;
  final String name;
  final String? phone;
  final String vehicleType;
  final double capacityKg;
  final String currentLocation;
  final String status;
  final double costPerKm;
  final double? rating;

  TransportProvider({
    this.id,
    required this.providerId,
    required this.name,
    this.phone,
    required this.vehicleType,
    required this.capacityKg,
    required this.currentLocation,
    this.status = 'available',
    required this.costPerKm,
    this.rating,
  });

  factory TransportProvider.fromJson(Map<String, dynamic> json) {
    return TransportProvider(
      id: json['id'],
      providerId: json['provider_id']?.toString() ?? json['id']?.toString() ?? 'PRV-${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: json['name'] ?? json['transporter_name'] ?? 'Fleet Transporter',
      phone: json['phone'] ?? json['contact'],
      vehicleType: json['vehicle_type'] ?? 'Medium Truck (10T)',
      capacityKg: (json['capacity_kg'] is num) ? (json['capacity_kg'] as num).toDouble() : double.tryParse('${json['capacity_kg']}') ?? 5000.0,
      currentLocation: json['current_location'] ?? json['location'] ?? 'Hub',
      status: json['status'] ?? 'available',
      costPerKm: (json['cost_per_km'] is num) ? (json['cost_per_km'] as num).toDouble() : double.tryParse('${json['cost_per_km']}') ?? 25.0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'name': name,
      if (phone != null) 'phone': phone,
      'vehicle_type': vehicleType,
      'capacity_kg': capacityKg,
      'current_location': currentLocation,
      'status': status,
      'cost_per_km': costPerKm,
    };
  }
}

class LogisticsQuoteRequest {
  final String origin;
  final String destination;
  final double weightKg;
  final String commodity;
  final String vehicleType;
  final bool returnEmptyDiscount;

  LogisticsQuoteRequest({
    required this.origin,
    required this.destination,
    required this.weightKg,
    required this.commodity,
    required this.vehicleType,
    this.returnEmptyDiscount = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'destination': destination,
      'weight_kg': weightKg,
      'commodity': commodity,
      'vehicle_type': vehicleType,
      'return_empty_discount': returnEmptyDiscount,
    };
  }
}

class LogisticsQuoteResult {
  final double distanceKm;
  final double baseCost;
  final double discountAmount;
  final double estimatedCost;
  final double discountPercent;
  final bool backhaulMatchFound;

  LogisticsQuoteResult({
    required this.distanceKm,
    required this.baseCost,
    required this.discountAmount,
    required this.estimatedCost,
    required this.discountPercent,
    required this.backhaulMatchFound,
  });

  factory LogisticsQuoteResult.fromJson(Map<String, dynamic> json) {
    final dist = (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : 180.0;
    final base = (json['base_cost'] is num) ? (json['base_cost'] as num).toDouble() : 5400.0;
    final est = (json['estimated_cost'] is num) ? (json['estimated_cost'] as num).toDouble() : 3780.0;
    final disc = (json['discount_amount'] is num) ? (json['discount_amount'] as num).toDouble() : (base - est);
    final discPct = (json['discount_percent'] is num) ? (json['discount_percent'] as num).toDouble() : 30.0;

    return LogisticsQuoteResult(
      distanceKm: dist,
      baseCost: base,
      discountAmount: disc,
      estimatedCost: est,
      discountPercent: discPct,
      backhaulMatchFound: json['backhaul_match_found'] ?? true,
    );
  }
}
