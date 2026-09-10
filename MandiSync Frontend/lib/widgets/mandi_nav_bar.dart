// =========================================================
// MANDISYNC FLUTTER — UNIFIED TOP HEADER & NAVIGATION BAR
// Matches Reference Image Top Header & MandiSync Brand Bar
// =========================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/auth/auth_modal.dart';
import '../screens/stats_screen.dart';
import '../screens/price_history_screen.dart';
import '../screens/history_screen.dart';
import '../screens/transactions_screen.dart';

class MandiNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final VoidCallback onStateChange;

  const MandiNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    required this.onStateChange,
  });

  @override
  State<MandiNavBar> createState() => _MandiNavBarState();
}

class _MandiNavBarState extends State<MandiNavBar> {
  final ApiService _api = ApiService();

  void _openAuthModal({int initialTab = 0}) async {
    final success = await AuthModal.show(context, initialTab: initialTab);
    if (success == true) {
      widget.onStateChange();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome, ${_api.currentUser?.fullName ?? 'User'}!"),
            backgroundColor: const Color(0xFF0B7A4B),
          ),
        );
      }
    }
  }

  void _showProfileMenu(BuildContext context) {
    if (!_api.isAuthenticated) {
      _openAuthModal(initialTab: 0);
      return;
    }

    final user = _api.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFEAF7F0),
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF0B7A4B), fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? "Farmer User", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("@${user?.username ?? 'user'}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEAF7F0), borderRadius: BorderRadius.circular(4)),
                            child: Text(user?.role ?? "Farmer", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF075B38))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // 1. Stats
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Color(0xFF0B7A4B)),
                  title: const Text("Stats", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Volume, orders & price performance", style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                  },
                ),

                // 2. Price History
                ListTile(
                  leading: const Icon(Icons.insights, color: Color(0xFF0284C7)),
                  title: const Text("Price History", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Daily historical Agmarknet mandi rates", style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceHistoryScreen()));
                  },
                ),

                // 3. History
                ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFFF59E0B)),
                  title: const Text("History", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Platform activity & predictions audit", style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                ),

                // 4. Transactions
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF10B981)),
                  title: const Text("Transactions", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Crop trade orders & escrow settlements", style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
                  },
                ),

                const Divider(),

                // 5. Log Out
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    await _api.logout();
                    if (mounted) {
                      widget.onStateChange();
                      setState(() {});
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Logged out successfully.")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Column(
      children: [
        // 1. TOP GOVERNMENT HEADER BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5ECE8), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Emblem & Ministry
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDFE7E2)),
                    ),
                    child: const Center(
                      child: Text("🏛️", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Government of India",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF123B2A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        "Ministry of Agriculture & Farmers Welfare",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right: Bell + Profile Avatar
              Row(
                children: [
                  // Bell
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 22, color: Color(0xFF334155)),
                    tooltip: "Notifications",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No new notifications"), duration: Duration(seconds: 2)),
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // Profile Icon / User Avatar with Popup Menu
                  if (_api.isAuthenticated) ...[
                    PopupMenuButton<String>(
                      tooltip: "Profile Menu",
                      offset: const Offset(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'stats') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                        } else if (value == 'price_history') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceHistoryScreen()));
                        } else if (value == 'history') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                        } else if (value == 'transactions') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
                        } else if (value == 'profile') {
                          widget.onNavigate(5); // Profile screen
                        } else if (value == 'logout') {
                          _api.logout().then((_) {
                            widget.onStateChange();
                            setState(() {});
                          });
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_api.currentUser?.fullName ?? "Farmer", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF123B2A))),
                              Text("@${_api.currentUser?.username ?? 'user'}", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              const Divider(),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stats',
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, size: 18, color: Color(0xFF0B7A4B)),
                              SizedBox(width: 10),
                              Text("Stats"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'price_history',
                          child: Row(
                            children: [
                              Icon(Icons.insights, size: 18, color: Color(0xFF0284C7)),
                              SizedBox(width: 10),
                              Text("Price History"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 10),
                              Text("History"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'transactions',
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long, size: 18, color: Color(0xFF10B981)),
                              SizedBox(width: 10),
                              Text("Transactions"),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.manage_accounts_outlined, size: 18, color: Color(0xFF123B2A)),
                              SizedBox(width: 10),
                              Text("Account Settings"),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text("Log Out", style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0B7A4B), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFEAF7F0),
                          child: Text(
                            (_api.currentUser?.fullName.isNotEmpty ?? false) ? _api.currentUser!.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0B7A4B)),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextButton.icon(
                      onPressed: () => _openAuthModal(initialTab: 0),
                      icon: const Icon(Icons.login, size: 16, color: Color(0xFF0B7A4B)),
                      label: const Text("Login", style: TextStyle(color: Color(0xFF0B7A4B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () => _openAuthModal(initialTab: 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B7A4B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Register"),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 2. MANDISYNC BRAND & NAVIGATION BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFDFE7E2), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo: Leaf + MandiSync
              InkWell(
                onTap: () => widget.onNavigate(0),
                child: const Row(
                  children: [
                    Text("🌿", style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    Text(
                      "MandiSync",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B7A4B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Nav Links (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    _buildNavLink(title: "Home", index: 0),
                    _buildNavLink(title: "Markets", index: 1),
                    _buildNavLink(title: "Analytics", index: 3), // Analytics tab
                    _buildNavLink(title: "Logistics", index: 4), // Logistics tab
                    PopupMenuButton<int>(
                      tooltip: "More Options",
                      offset: const Offset(0, 36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              "More",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: (widget.selectedIndex == 2 || widget.selectedIndex == 5)
                                    ? const Color(0xFF0B7A4B)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF475569)),
                          ],
                        ),
                      ),
                      onSelected: (idx) {
                        if (idx == 5) {
                          _showProfileMenu(context);
                        } else {
                          widget.onNavigate(idx);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 2, child: Text("Sell Crops (Farmer Listing)")),
                        const PopupMenuItem(value: 5, child: Text("My Account / Profile Hub")),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavLink({required String title, required int index}) {
    final isActive = widget.selectedIndex == index;

    return InkWell(
      onTap: () => widget.onNavigate(index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0B7A4B) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? const Color(0xFF0B7A4B) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
