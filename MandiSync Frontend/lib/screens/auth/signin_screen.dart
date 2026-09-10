// =========================================================
// MANDISYNC FLUTTER — SIGN IN SCREEN
// =========================================================

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await _api.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  void _showAadhaarDialog() {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text("🪪 "),
            Text("Aadhaar OTP Login"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("UIDAI OTP has been dispatched to your linked mobile number.", style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: "6-Digit OTP", hintText: "123456"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (otpCtrl.text.isEmpty) return;
              final navCtx = Navigator.of(ctx);
              final navParent = Navigator.of(context);
              await _api.setToken("mock_aadhaar_jwt_${DateTime.now().millisecondsSinceEpoch}");
              navCtx.pop();
              navParent.pop(true);
            },
            child: const Text("Verify OTP"),
          ),
        ],
      ),
    );
  }

  void _showDigiLockerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text("🔐 "),
            Text("DigiLocker Auth"),
          ],
        ),
        content: const Text(
          "Connecting to National DigiLocker Gateway. Verified Farmer Land Title (7/12) and KYC retrieved.",
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final navCtx = Navigator.of(ctx);
              final navParent = Navigator.of(context);
              await _api.setToken("mock_digilocker_jwt_${DateTime.now().millisecondsSinceEpoch}");
              navCtx.pop();
              navParent.pop(true);
            },
            child: const Text("Proceed to Account"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFEAF7F0),
                  child: Text("M", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0B7A4B))),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Welcome to MandiSync",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
                ),
                const Text("Sign in using your FastAPI credentials", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person)),
                        validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                        validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
                      ),
                      const SizedBox(height: 18),

                      if (_errorMsg != null) ...[
                        Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        const SizedBox(height: 10),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B7A4B), foregroundColor: Colors.white),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign In"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR VERIFY WITH", style: TextStyle(fontSize: 11, color: Colors.grey))),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showAadhaarDialog,
                        icon: const Text("🪪"),
                        label: const Text("Aadhaar OTP"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDigiLockerDialog,
                        icon: const Text("🔐"),
                        label: const Text("DigiLocker"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: const Text("Don't have an account? Register here →", style: TextStyle(color: Color(0xFF0B7A4B))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
