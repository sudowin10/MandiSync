// =========================================================
// MANDISYNC FLUTTER — REGISTER SCREEN
// =========================================================

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = "Farmer";
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final payload = {
      'role': _selectedRole,
      'full_name': _fullNameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
    };

    try {
      await _api.register(payload);
      // Auto-login
      try {
        await _api.login(payload['username']!, payload['password']!);
      } catch (_) {}

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account registered successfully!"), backgroundColor: Color(0xFF0B7A4B)),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Join MandiSync Platform",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
                  ),
                  const Text("Select your role in the agricultural supply chain", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(labelText: "Account Role *", prefixIcon: Icon(Icons.badge)),
                    items: const [
                      DropdownMenuItem(value: "Farmer", child: Text("Farmer / FPO (Produce Seller)")),
                      DropdownMenuItem(value: "Trader", child: Text("Trader / Commission Agent")),
                      DropdownMenuItem(value: "Buyer", child: Text("Institutional Buyer / Processor")),
                      DropdownMenuItem(value: "Mandi Admin", child: Text("APMC Mandi Administrator")),
                    ],
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(labelText: "Full Name *", hintText: "Ramesh Kumar"),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: "Username *", hintText: "ramesh_kisan"),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email Address *", hintText: "ramesh@example.com"),
                    validator: (v) => v == null || !v.contains("@") ? "Valid email required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Mobile Number *", hintText: "9876543210"),
                    validator: (v) => v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password *", hintText: "Minimum 6 characters"),
                    validator: (v) => v == null || v.length < 6 ? "Minimum 6 characters" : null,
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
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B7A4B), foregroundColor: Colors.white),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("🌾 Register Profile"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
