// =========================================================
// MANDISYNC FLUTTER — USER PROFILE HUB SCREEN
// Features Required Options: Stats, Price History, History, Transactions, Log Out
// =========================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'auth/auth_modal.dart';
import 'stats_screen.dart';
import 'price_history_screen.dart';
import 'history_screen.dart';
import 'transactions_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onStateChange;

  const ProfileScreen({super.key, required this.onStateChange});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (!_api.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final u = await _api.getMe();
      if (mounted) {
        setState(() {
          _user = u;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _user = _api.currentUser;
          _isLoading = false;
        });
      }
    }
  }

  void _openAuth(int initialTab) async {
    final res = await AuthModal.show(context, initialTab: initialTab);
    if (res == true) {
      widget.onStateChange();
      _loadUser();
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to sign out of your MandiSync account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _api.logout();
      widget.onStateChange();
      _loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Logged out successfully.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // GUEST / NOT LOGGED IN STATE
    if (!_api.isAuthenticated || _user == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC7EBD7), width: 2),
                  ),
                  child: const Icon(Icons.account_circle, size: 48, color: Color(0xFF0B7A4B)),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Farmer & Buyer Profile Hub",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to access your farm performance stats, historical price analytics, activity records, and order transactions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openAuth(0),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text("Sign In"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B7A4B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAuth(1),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text("Register"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // LOGGED IN STATE: SHOWS STATS, PRICE HISTORY, HISTORY, TRANSACTIONS, LOG OUT
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. USER PROFILE CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDFE7E2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFEAF7F0),
                      child: Text(
                        _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B)),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _user!.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF123B2A)),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _user!.role,
                                  style: const TextStyle(color: Color(0xFF075B38), fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("@${_user!.username} • ${_user!.email}", style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text("Aadhaar Verified • ONDC Network Registered", style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Account Options & Activity Hub",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF123B2A)),
              ),
              const SizedBox(height: 12),

              // 2. THE 5 REQUIRED OPTIONS:
              // 1. Stats
              _buildOptionCard(
                icon: Icons.bar_chart,
                iconColor: const Color(0xFF0B7A4B),
                title: "Stats",
                desc: "Market sales volume, active order counts, and price gains",
                badge: "Live Dashboard",
                badgeColor: const Color(0xFFEAF7F0),
                badgeTextColor: const Color(0xFF075B38),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),

              // 2. Price History
              _buildOptionCard(
                icon: Icons.insights,
                iconColor: const Color(0xFF0284C7),
                title: "Price History",
                desc: "Daily Agmarknet mandi historical rates, arrivals, and price ranges",
                badge: "Agmarknet Feed",
                badgeColor: const Color(0xFFF0F9FF),
                badgeTextColor: const Color(0xFF0284C7),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceHistoryScreen())),
              ),

              // 3. History
              _buildOptionCard(
                icon: Icons.history,
                iconColor: const Color(0xFFF59E0B),
                title: "History",
                desc: "Complete audit log of predictions, shipments, and listings",
                badge: "Activity Log",
                badgeColor: const Color(0xFFFFFBEB),
                badgeTextColor: const Color(0xFFB45309),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),

              // 4. Transactions
              _buildOptionCard(
                icon: Icons.receipt_long,
                iconColor: const Color(0xFF10B981),
                title: "Transactions",
                desc: "Crop sales orders, buyer invoices, and escrow lock status",
                badge: "Escrow Protected",
                badgeColor: const Color(0xFFEAF7F0),
                badgeTextColor: const Color(0xFF075B38),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
              ),

              const SizedBox(height: 14),

              // 5. Log Out Option
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: ListTile(
                  onTap: _handleLogout,
                  leading: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFFEF2F2),
                    child: Icon(Icons.logout, color: Color(0xFFDC2626), size: 20),
                  ),
                  title: const Text(
                    "Log Out",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFFDC2626)),
                  ),
                  subtitle: const Text(
                    "Sign out from current session and return to guest mode",
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDFE7E2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF123B2A))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
              child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
