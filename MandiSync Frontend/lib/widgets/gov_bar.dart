import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/app_provider.dart';

class GovBar extends StatelessWidget {
  const GovBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProv = context.watch<AppProvider>();
    final isOnline = appProv.isBackendHealthy;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Government of India · Ministry of Agriculture & Farmers Welfare',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppTheme.onlineGreen : AppTheme.errorRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  appProv.healthStatusText,
                  style: TextStyle(
                    color: isOnline ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
