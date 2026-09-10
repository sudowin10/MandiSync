import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

class AppNavDrawer extends StatelessWidget {
  final String activeRoute;

  const AppNavDrawer({
    super.key,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            color: AppTheme.darkSlate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MandiSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isAuth && user != null) ...[
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${user.role} · Authorized Citizen',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Smart Agriculture Platform',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  route: '/',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'Markets & Mandi Rates',
                  route: '/markets',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.grass_outlined,
                  title: 'Sell Crops',
                  route: '/crop-listing',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.psychology_outlined,
                  title: 'XGBoost AI Analytics',
                  route: '/analytics',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: 'Fleet & Logistics',
                  route: '/logistics',
                ),
                const Divider(),
                if (isAuth) ...[
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    route: '/profile',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Dashboard Stats',
                    route: '/stats',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Transactions',
                    route: '/transactions',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history_outlined,
                    title: 'Activity History',
                    route: '/history',
                  ),
                ] else ...[
                  _buildNavItem(
                    context,
                    icon: Icons.login,
                    title: 'Sign In',
                    route: '/signin',
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_add_alt,
                    title: 'Register Citizen Account',
                    route: '/register',
                  ),
                ],
              ],
            ),
          ),
          if (isAuth)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Log Out'),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = activeRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppTheme.primaryGreen : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.primaryGreen : AppTheme.darkSlate,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.subtleGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
