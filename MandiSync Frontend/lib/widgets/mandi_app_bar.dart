import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

class MandiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const MandiAppBar({
    super.key,
    this.title = 'MandiSync',
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated;

    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, '/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MandiSync',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkSlate,
                    letterSpacing: -0.5,
                  ),
                ),
                if (title != 'MandiSync')
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (isAuth && user != null) ...[
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryDark,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.fullName.split(' ').first,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkSlate,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                ],
              ),
            ),
            onSelected: (val) async {
              switch (val) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'crops':
                  Navigator.pushNamed(context, '/crop-listing');
                  break;
                case 'stats':
                  Navigator.pushNamed(context, '/stats');
                  break;
                case 'transactions':
                  Navigator.pushNamed(context, '/transactions');
                  break;
                case 'history':
                  Navigator.pushNamed(context, '/history');
                  break;
                case 'logout':
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                  break;
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                      ),
                    ),
                    Text(
                      user.role,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'crops',
                child: Row(
                  children: [
                    Icon(Icons.agriculture_outlined, size: 20, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Text('My Crop Listings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Text('Dashboard Stats'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'transactions',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 20, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Text('Transactions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: AppTheme.primaryGreen),
                    SizedBox(width: 10),
                    Text('Activity History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppTheme.errorRed),
                    SizedBox(width: 10),
                    Text('Log Out', style: TextStyle(color: AppTheme.errorRed)),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signin'),
            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text('Register', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
        ],
      ],
    );
  }
}
