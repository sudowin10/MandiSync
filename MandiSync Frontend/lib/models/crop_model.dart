class CropModel {
  final dynamic id;
  final String cropName;
  final String? commodity;
  final String? variety;
  final String? category;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final String location;
  final String? state;
  final String? harvestDate;
  final String? description;
  final bool isOrganic;
  final String? grade;
  final String? contactPhone;
  final String status;
  final String? createdAt;

  CropModel({
    this.id,
    required this.cropName,
    this.commodity,
    this.variety,
    this.category,
    required this.quantity,
    this.unit = 'Quintal',
    required this.pricePerUnit,
    required this.location,
    this.state,
    this.harvestDate,
    this.description,
    this.isOrganic = false,
    this.grade,
    this.contactPhone,
    this.status = 'active',
    this.createdAt,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] ?? json['crop_id'],
      cropName: json['crop_name'] ?? json['commodity'] ?? 'Agricultural Produce',
      commodity: json['commodity'] ?? json['crop_name'],
      variety: json['variety'],
      category: json['category'],
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : double.tryParse('${json['quantity']}') ?? 0.0,
      unit: json['unit'] ?? 'Quintal',
      pricePerUnit: (json['price_per_unit'] is num)
          ? (json['price_per_unit'] as num).toDouble()
          : (json['price'] is num)
              ? (json['price'] as num).toDouble()
              : double.tryParse('${json['price_per_unit'] ?? json['price']}') ?? 0.0,
      location: json['location'] ?? json['mandi'] ?? 'Mandi Market',
      state: json['state'],
      harvestDate: json['harvest_date'],
      description: json['description'],
      isOrganic: json['is_organic'] == true || json['is_organic'] == 'true',
      grade: json['grade'],
      contactPhone: json['contact_phone'] ?? json['phone'],
      status: json['status'] ?? 'active',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'crop_name': cropName,
      'commodity': commodity ?? cropName,
      if (variety != null) 'variety': variety,
      if (category != null) 'category': category,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'location': location,
      if (state != null) 'state': state,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (description != null) 'description': description,
      'is_organic': isOrganic,
      if (grade != null) 'grade': grade,
      if (contactPhone != null) 'contact_phone': contactPhone,
      'status': status,
    };
  }
}
