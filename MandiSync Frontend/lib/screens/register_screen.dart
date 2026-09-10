import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gov_bar.dart';
import '../widgets/mandi_app_bar.dart';
import '../widgets/aadhaar_otp_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  String _role = 'Farmer';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _stateCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final payload = {
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'full_name': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'role': _role,
      'state': _stateCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
    };

    final success = await auth.register(payload);
    if (mounted) {
      if (success) {
        // Auto-login or proceed
        await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.primaryGreen,
              content: Text('Registration successful! Welcome to MandiSync.'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.errorRed,
            content: Text(auth.errorMessage ?? 'Registration failed. Try a different username.'),
          ),
        );
      }
    }
  }

  void _triggerAadhaar() async {
    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AadhaarOtpDialog(isLogin: false),
    );
    if (verified == true && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: const MandiAppBar(title: 'Register Citizen Account', showBackButton: true),
      body: Column(
        children: [
          const GovBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Join MandiSync Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkSlate,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connect with APMC Mandis, AI Forecasting, and ONDC open network',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 20),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _fullNameCtrl,
                                  decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'Ramesh Patel'),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _usernameCtrl,
                                        decoration: const InputDecoration(labelText: 'Username *', hintText: 'ramesh_patel'),
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _role,
                                        decoration: const InputDecoration(labelText: 'Role *'),
                                        items: ['Farmer', 'Trader', 'FPO Member', 'Logistics Transporter', 'APMC Official']
                                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                            .toList(),
                                        onChanged: (v) => setState(() => _role = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneCtrl,
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(labelText: 'Mobile Number *', hintText: '+91 98765 43210'),
                                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailCtrl,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: const InputDecoration(labelText: 'Email Address', hintText: 'ramesh@example.com'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _stateCtrl,
                                        decoration: const InputDecoration(labelText: 'State', hintText: 'Maharashtra'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _districtCtrl,
                                        decoration: const InputDecoration(labelText: 'District', hintText: 'Nashik'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Create Password *',
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.length < 4) ? 'Minimum 4 characters' : null,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                  onPressed: auth.isLoading ? null : _handleRegister,
                                  child: auth.isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Complete Citizen Registration'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: AppTheme.primaryDark,
                          side: const BorderSide(color: AppTheme.borderGreen, width: 1.5),
                        ),
                        icon: const Text('🪪', style: TextStyle(fontSize: 18)),
                        label: const Text('Fast Track with Aadhaar e-KYC (Instant Verify)'),
                        onPressed: _triggerAadhaar,
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already registered? ', style: TextStyle(color: AppTheme.textSecondary)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
                            child: const Text('Sign In here', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
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
