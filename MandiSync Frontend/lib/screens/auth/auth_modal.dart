// =========================================================
// MANDISYNC FLUTTER — AUTHENTICATION MODAL (LOGIN & REGISTER)
// =========================================================

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AuthModal extends StatefulWidget {
  final int initialTabIndex; // 0 for Login, 1 for Register
  const AuthModal({super.key, this.initialTabIndex = 0});

  static Future<bool?> show(BuildContext context, {int initialTab = 0}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AuthModal(initialTabIndex: initialTab),
        ),
      ),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  // Login Controllers
  final _loginUsernameCtrl = TextEditingController(text: "farmer_user");
  final _loginPasswordCtrl = TextEditingController(text: "password123");
  bool _isLoggingIn = false;
  String? _loginError;

  // Register Controllers
  final _regNameCtrl = TextEditingController(text: "Ramesh Patil");
  final _regUsernameCtrl = TextEditingController(text: "ramesh_patil");
  final _regEmailCtrl = TextEditingController(text: "ramesh.patil@kisan.gov.in");
  final _regPasswordCtrl = TextEditingController(text: "password123");
  String _selectedRole = "Farmer";
  bool _isRegistering = false;
  String? _regError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regUsernameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _loginUsernameCtrl.text.trim();
    final password = _loginPasswordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _loginError = "Username and password are required.");
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      await _api.login(username, password);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = e.toString().replaceAll("Exception: ", "");
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final username = _regUsernameCtrl.text.trim();
    final password = _regPasswordCtrl.text.trim();
    final fullName = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _regError = "Username and password are required.");
      return;
    }

    setState(() {
      _isRegistering = true;
      _regError = null;
    });

    try {
      await _api.register({
        'username': username,
        'password': password,
        'full_name': fullName,
        'email': email,
        'role': _selectedRole,
      });
      // After registration, auto-login
      await _api.login(username, password);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _regError = e.toString().replaceAll("Exception: ", "");
          _isRegistering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: const Color(0xFF123B2A),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.agriculture, color: Color(0xFFE5F0EA), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MandiSync Portal",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Ministry of Agriculture & Farmers Welfare",
                      style: TextStyle(color: Color(0xFFB4D2C3), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0B7A4B),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF0B7A4B),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Sign In"),
            Tab(text: "Create Account"),
          ],
        ),

        // Tab Views
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return _tabController.index == 0 ? _buildLoginForm() : _buildRegisterForm();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome to MandiSync",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
        ),
        const SizedBox(height: 4),
        Text(
          "Sign in with your registered farmer or buyer credentials.",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 18),

        if (_loginError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_loginError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              ],
            ),
          ),
        ],

        TextField(
          controller: _loginUsernameCtrl,
          decoration: const InputDecoration(
            labelText: "Username",
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _loginPasswordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "💡 Demo Tip: Pre-filled credentials (farmer_user / password123) are ready to use.",
            style: TextStyle(color: Color(0xFF075B38), fontSize: 11),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isLoggingIn ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B7A4B),
              foregroundColor: Colors.white,
            ),
            child: _isLoggingIn
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Sign In to Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),

        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(1),
            child: const Text("Don't have an account? Register here"),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Join the MandiSync Network",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF123B2A)),
        ),
        const SizedBox(height: 4),
        Text(
          "Direct access to APMC mandi rates, AI forecasting, and ONDC trade.",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (_regError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_regError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              ],
            ),
          ),
        ],

        TextField(
          controller: _regNameCtrl,
          decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.badge_outlined)),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regUsernameCtrl,
                decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person_outline)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: "Role"),
                items: ["Farmer", "Trader", "Buyer", "FPO Admin"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regEmailCtrl,
          decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _regPasswordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Create Password", prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isRegistering ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B7A4B),
              foregroundColor: Colors.white,
            ),
            child: _isRegistering
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Create MandiSync Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),

        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => _tabController.animateTo(0),
            child: const Text("Already registered? Sign in here"),
          ),
        ),
      ],
    );
  }
}
