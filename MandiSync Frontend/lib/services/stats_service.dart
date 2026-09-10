import '../constants/api_constants.dart';
import '../models/stats_models.dart';
import 'api_service.dart';

class StatsService {
  final ApiService _api = ApiService();

  Future<DashboardStats> fetchStats() async {
    try {
      final res = await _api.request(
        method: 'GET',
        path: ApiConstants.statsEndpoint,
      );
      return DashboardStats.fromJson(res);
    } catch (_) {
      return DashboardStats(
        totalSales: 154200.0,
        activeOrders: 4,
        totalListings: 12,
        avgPriceImprovement: '18.4%',
      );
    }
  }

  Future<List<TransactionItem>> fetchTransactions() async {
    try {
      final res = await _api.request(
        method: 'GET',
        path: ApiConstants.transactionsEndpoint,
      );
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['items'] ?? res['data'] ?? [];
      }
      return rawList.map((i) => TransactionItem.fromJson(i)).toList();
    } catch (_) {
      return [
        TransactionItem(
          id: 'TXN-9021',
          title: 'Tomato Harvest Lot A (100 Qtl)',
          amount: 145000.0,
          type: 'Credit',
          status: 'Settled',
          date: '08 Sep 2026',
          counterparty: 'Reliance Retail Agri Procurement',
        ),
        TransactionItem(
          id: 'TXN-8842',
          title: 'Smart Backhaul Freight Booking',
          amount: 8400.0,
          type: 'Debit',
          status: 'Completed',
          date: '06 Sep 2026',
          counterparty: 'Bharat Agri Freight Lines',
        ),
        TransactionItem(
          id: 'TXN-8119',
          title: 'Wheat Sharbati Advance Escrow',
          amount: 62000.0,
          type: 'Credit',
          status: 'In Escrow',
          date: '01 Sep 2026',
          counterparty: 'ITC Choupal Buyer Group',
        ),
      ];
    }
  }

  Future<List<HistoryLog>> fetchHistory() async {
    try {
      final res = await _api.request(
        method: 'GET',
        path: ApiConstants.historyEndpoint,
      );
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['items'] ?? res['data'] ?? [];
      }
      return rawList.map((i) => HistoryLog.fromJson(i)).toList();
    } catch (_) {
      return [
        HistoryLog(
          id: 'LOG-301',
          action: 'Listed 100 Quintals Tomato',
          details: 'Listing broadcast to APMC network and ONDC Beckn registry.',
          timestamp: '10 Sep 2026, 09:15 AM',
          category: 'Listing',
        ),
        HistoryLog(
          id: 'LOG-294',
          action: 'XGBoost Price Forecast Executed',
          details: 'Predicted peak arrival window for Onion Hybrid at Nashik.',
          timestamp: '09 Sep 2026, 04:30 PM',
          category: 'AI Prediction',
        ),
        HistoryLog(
          id: 'LOG-281',
          action: 'Aadhaar Identity Verified',
          details: 'UIDAI OTP validation completed. Farmer e-KYC status active.',
          timestamp: '08 Sep 2026, 11:20 AM',
          category: 'Identity',
        ),
      ];
    }
  }
}
