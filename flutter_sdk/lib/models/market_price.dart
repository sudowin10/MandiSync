class AgmarknetPriceRecord {
  final String? id;
  final String commodity;
  final String? variety;
  final String market;
  final String state;
  final String? district;
  final double? minPrice;
  final double? maxPrice;
  final double modalPrice;
  final double? arrivalTonnes;
  final String? arrivalDate;

  const AgmarknetPriceRecord({
    this.id,
    required this.commodity,
    this.variety,
    required this.market,
    required this.state,
    this.district,
    this.minPrice,
    this.maxPrice,
    required this.modalPrice,
    this.arrivalTonnes,
    this.arrivalDate,
  });

  factory AgmarknetPriceRecord.fromJson(Map<String, dynamic> json) {
    return AgmarknetPriceRecord(
      id: json['id'] as String? ?? json['_id'] as String?,
      commodity: json['commodity'] as String? ?? 'Unknown',
      variety: json['variety'] as String? ?? 'Standard',
      market: json['market'] as String? ?? 'Mandi',
      state: json['state'] as String? ?? '',
      district: json['district'] as String?,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      arrivalTonnes: (json['arrival_tonnes'] ?? json['arrival_volume'] as num?)?.toDouble(),
      arrivalDate: json['arrival_date'] as String? ?? json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'commodity': commodity,
    'variety': variety,
    'market': market,
    'state': state,
    'district': district,
    'min_price': minPrice,
    'max_price': maxPrice,
    'modal_price': modalPrice,
    'arrival_tonnes': arrivalTonnes,
    'arrival_date': arrivalDate,
  };
}
