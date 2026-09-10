class DashboardStats {
  final double totalSales;
  final int activeOrders;
  final int totalListings;
  final String avgPriceImprovement;

  DashboardStats({
    required this.totalSales,
    required this.activeOrders,
    required this.totalListings,
    required this.avgPriceImprovement,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalSales: (json['total_sales'] is num) ? (json['total_sales'] as num).toDouble() : 154200.0,
      activeOrders: json['active_orders'] ?? 4,
      totalListings: json['total_listings'] ?? 12,
      avgPriceImprovement: json['avg_price_improvement']?.toString() ?? '18.4%',
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final String type;
  final String status;
  final String date;
  final String? counterparty;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
    this.counterparty,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id']?.toString() ?? 'TXN-${DateTime.now().millisecondsSinceEpoch % 10000}',
      title: json['title'] ?? json['crop'] ?? 'Crop Escrow Settlement',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 12000.0,
      type: json['type'] ?? 'Credit',
      status: json['status'] ?? 'Completed',
      date: json['date'] ?? json['created_at'] ?? 'Today',
      counterparty: json['counterparty'] ?? json['buyer'] ?? 'Verified Mandi Trader',
    );
  }
}

class HistoryLog {
  final String id;
  final String action;
  final String details;
  final String timestamp;
  final String category;

  HistoryLog({
    required this.id,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.category,
  });

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      id: json['id']?.toString() ?? 'HIST-${DateTime.now().millisecondsSinceEpoch % 10000}',
      action: json['action'] ?? 'Platform Activity',
      details: json['details'] ?? json['message'] ?? 'Action completed successfully.',
      timestamp: json['timestamp'] ?? json['created_at'] ?? 'Recent',
      category: json['category'] ?? 'System',
    );
  }
}
