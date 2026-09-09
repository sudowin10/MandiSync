class CropRecord {
  final String? id;
  final String name;
  final String category;
  final double? msp;
  final int shelfLifeDays;
  final String? standardGrade;
  final String? imageUrl;

  const CropRecord({
    this.id,
    required this.name,
    required this.category,
    this.msp,
    this.shelfLifeDays = 14,
    this.standardGrade,
    this.imageUrl,
  });

  factory CropRecord.fromJson(Map<String, dynamic> json) {
    return CropRecord(
      id: json['id'] as String? ?? json['_id'] as String?,
      name: json['name'] as String? ?? json['crop_name'] as String? ?? 'Crop',
      category: json['category'] as String? ?? 'VEGETABLE',
      msp: (json['msp'] as num?)?.toDouble(),
      shelfLifeDays: (json['shelf_life_days'] as num?)?.toInt() ?? 14,
      standardGrade: json['standard_grade'] as String? ?? 'Grade A',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'msp': msp,
    'shelf_life_days': shelfLifeDays,
    'standard_grade': standardGrade,
    'image_url': imageUrl,
  };
}
