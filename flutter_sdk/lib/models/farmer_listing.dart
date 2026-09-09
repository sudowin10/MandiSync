class CreateFarmerListingRequest {
  final String cropName;
  final double quantity;
  final String unit; // 'QUINTAL', 'KG', 'TONNE'
  final double price;
  final String location;
  final String? variety;
  final String? qualityGrade; // 'GRADE_A', 'GRADE_B', 'GRADE_C'
  final String? harvestDate;

  const CreateFarmerListingRequest({
    required this.cropName,
    required this.quantity,
    this.unit = 'QUINTAL',
    required this.price,
    required this.location,
    this.variety,
    this.qualityGrade = 'GRADE_A',
    this.harvestDate,
  });

  Map<String, dynamic> toJson() => {
    'crop_name': cropName,
    'quantity': quantity,
    'unit': unit,
    'price': price,
    'location': location,
    if (variety != null) 'variety': variety,
    if (qualityGrade != null) 'quality_grade': qualityGrade,
    if (harvestDate != null) 'harvest_date': harvestDate,
  };
}

class FarmerListingResponse {
  final String id;
  final String cropName;
  final double price;
  final double availableQuantity;
  final String unit;
  final String location;
  final String? createdAt;

  const FarmerListingResponse({
    required this.id,
    required this.cropName,
    required this.price,
    required this.availableQuantity,
    required this.unit,
    required this.location,
    this.createdAt,
  });

  factory FarmerListingResponse.fromJson(Map<String, dynamic> json) {
    final quantityObj = json['quantity'] as Map<String, dynamic>?;
    final priceObj = json['price'] as Map<String, dynamic>?;
    final locationObj = json['location'] as Map<String, dynamic>?;

    return FarmerListingResponse(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? json['name'] as String? ?? '',
      price: (priceObj != null ? priceObj['value'] : json['price'] as num?)?.toDouble() ?? 0.0,
      availableQuantity: (quantityObj != null ? quantityObj['available_quantity'] : json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: (quantityObj != null ? quantityObj['unit'] : json['unit'] as String?) ?? 'QUINTAL',
      location: (locationObj != null ? locationObj['city'] : json['location'] as String?) ?? 'Mandi Hub',
      createdAt: json['created_at'] as String?,
    );
  }
}
