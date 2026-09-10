import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/app_nav_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _fullNameCtrl.text = user.fullName;
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.phone ?? '';
      _stateCtrl.text = user.state ?? '';
      _districtCtrl.text = user.district ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final payload = {
      'full_name': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
    };

    final success = await auth.updateProfile(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('Profile details updated successfully!'),
          ),
        );
      }
    }
  }

  void _confirmDeactivation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: const Text('Are you sure you want to deactivate your MandiSync account? This will log you out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().deactivateAccount();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Confirm Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user != null && _fullNameCtrl.text.isEmpty && !_isSaving) {
      _fullNameCtrl.text = user.fullName;
      _emailCtrl.text = user.email ?? '';
      _phoneCtrl.text = user.phone ?? '';
      _stateCtrl.text = user.state ?? '';
      _districtCtrl.text = user.district ?? '';
    }

    return Scaffold(
      appBar: const MandiAppBar(title: 'Citizen Profile'),
      drawer: const AppNavDrawer(activeRoute: '/profile'),
      body: Column(
        children: [
          const GovBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PROFILE HEADER CARD
                      Card(
                        color: AppTheme.subtleGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppTheme.borderGreen),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryDark,
                                child: Text(
                                  user?.initials ?? 'U',
                                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Authorized Citizen',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user?.role ?? 'Farmer',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'UIDAI e-KYC Active ✓',
                                          style: TextStyle(color: AppTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // EDIT FORM
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Personal & Regional Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Synced with Ministry of Agriculture portal', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const Divider(height: 24),

                              TextField(controller: _fullNameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                              const SizedBox(height: 12),
                              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                              const SizedBox(height: 12),
                              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(child: TextField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextField(controller: _districtCtrl, decoration: const InputDecoration(labelText: 'District'))),
                                ],
                              ),
                              const SizedBox(height: 20),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                onPressed: _isSaving ? null : _handleSave,
                                child: _isSaving
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Save Profile Updates'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // DANGER ZONE
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Deactivate Account', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                                  Text('Temporarily deactivate access to MandiSync', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side: const BorderSide(color: AppTheme.errorRed),
                                ),
                                onPressed: _confirmDeactivation,
                                child: const Text('Deactivate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
