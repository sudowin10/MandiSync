class MarketPriceModel {
  final dynamic id;
  final String cropName;
  final String market;
  final String state;
  final String? district;
  final String? variety;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String? date;
  final double? arrivals;

  MarketPriceModel({
    this.id,
    required this.cropName,
    required this.market,
    required this.state,
    this.district,
    this.variety,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    this.date,
    this.arrivals,
  });

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    return MarketPriceModel(
      id: json['id'],
      cropName: json['crop_name'] ?? json['commodity'] ?? 'Commodity',
      market: json['market'] ?? json['mandi'] ?? 'Local Mandi',
      state: json['state'] ?? 'India',
      district: json['district'],
      variety: json['variety'] ?? 'Standard',
      minPrice: (json['min_price'] is num) ? (json['min_price'] as num).toDouble() : double.tryParse('${json['min_price']}') ?? 0.0,
      maxPrice: (json['max_price'] is num) ? (json['max_price'] as num).toDouble() : double.tryParse('${json['max_price']}') ?? 0.0,
      modalPrice: (json['modal_price'] is num) ? (json['modal_price'] as num).toDouble() : double.tryParse('${json['modal_price']}') ?? 0.0,
      date: json['date'] ?? json['arrival_date'],
      arrivals: (json['arrivals'] is num) ? (json['arrivals'] as num).toDouble() : double.tryParse('${json['arrivals']}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'crop_name': cropName,
      'market': market,
      'state': state,
      if (district != null) 'district': district,
      if (variety != null) 'variety': variety,
      'min_price': minPrice,
      'max_price': maxPrice,
      'modal_price': modalPrice,
      if (date != null) 'date': date,
      if (arrivals != null) 'arrivals': arrivals,
    };
  }
}
