class TransactionRecord {
  final String id;
  final String orderId;
  final String cropName;
  final double amountInr;
  final String status; // 'SUCCESS', 'PENDING', 'COMPLETED'
  final String date;
  final String? buyerName;
  final String? sellerName;

  const TransactionRecord({
    required this.id,
    required this.orderId,
    required this.cropName,
    required this.amountInr,
    required this.status,
    required this.date,
    this.buyerName,
    this.sellerName,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String? ?? json['transaction_id'] as String? ?? 'TX-0',
      orderId: json['order_id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? json['commodity'] as String? ?? 'Produce',
      amountInr: (json['amount_inr'] as num? ?? json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'COMPLETED',
      date: json['date'] as String? ?? json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      buyerName: json['buyer_name'] as String?,
      sellerName: json['seller_name'] as String?,
    );
  }
}

class DashboardStats {
  final double totalSales;
  final int activeOrders;
  final int totalFarmers;
  final int availableTrucks;

  const DashboardStats({
    required this.totalSales,
    required this.activeOrders,
    this.totalFarmers = 19,
    this.availableTrucks = 31,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 15000.0,
      activeOrders: (json['active_orders'] as num?)?.toInt() ?? 4,
      totalFarmers: (json['total_farmers'] as num?)?.toInt() ?? 19,
      availableTrucks: (json['available_trucks'] as num?)?.toInt() ?? 31,
    );
  }
}
