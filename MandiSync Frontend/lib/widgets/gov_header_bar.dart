// =========================================================
// MANDISYNC FLUTTER — GOVERNMENT HEADER BAR
// =========================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GovHeaderBar extends StatefulWidget {
  const GovHeaderBar({super.key});

  @override
  State<GovHeaderBar> createState() => _GovHeaderBarState();
}

class _GovHeaderBarState extends State<GovHeaderBar> {
  bool _isOnline = false;
  String _statusText = "Checking API...";

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final res = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _isOnline = res['online'] ?? false;
        _statusText = res['text'] ?? (_isOnline ? "API Online" : "API Offline");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF123B2A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Text("🇮🇳 ", style: TextStyle(fontSize: 14)),
              Text(
                "Government of India · Ministry of Agriculture & Farmers Welfare",
                style: TextStyle(
                  color: Color(0xFFE5F0EA),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _checkStatus,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: _isOnline
                          ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 4)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Color(0xFFE5F0EA),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
