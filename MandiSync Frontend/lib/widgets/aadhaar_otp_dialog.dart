import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

class AadhaarOtpDialog extends StatefulWidget {
  final bool isLogin;

  const AadhaarOtpDialog({super.key, this.isLogin = false});

  @override
  State<AadhaarOtpDialog> createState() => _AadhaarOtpDialogState();
}

class _AadhaarOtpDialogState extends State<AadhaarOtpDialog> {
  final TextEditingController _otpController = TextEditingController();
  String? _referenceId;
  bool _isInitiating = true;
  String? _statusMessage;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _initiateAadhaar();
  }

  Future<void> _initiateAadhaar() async {
    final auth = context.read<AuthProvider>();
    try {
      final ref = await auth.startAadhaar();
      if (mounted) {
        setState(() {
          _referenceId = ref;
          _isInitiating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _referenceId = 'REF-UIDAI-${DateTime.now().millisecondsSinceEpoch % 100000}';
          _isInitiating = false;
        });
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _statusMessage = 'Please enter valid OTP received on Aadhaar mobile.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = 'Verifying with UIDAI gateway...';
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyAadhaarOtp(_referenceId ?? 'REF-UIDAI', otp);

    if (mounted) {
      setState(() => _isVerifying = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryGreen,
            content: Text('Aadhaar verified successfully! Welcome to MandiSync.'),
          ),
        );
      } else {
        setState(() => _statusMessage = auth.errorMessage ?? 'Aadhaar verification failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.subtleGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🪪', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aadhaar e-KYC Verification',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        'National UIDAI Gateway',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isInitiating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.subtleGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reference ID: ${_referenceId ?? "UIDAI-ACTIVE"}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Enter 6-Digit Aadhaar OTP',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  hintText: '123456',
                  counterText: '',
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusMessage!.contains('failed') ? AppTheme.errorRed : AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isLogin ? 'Confirm & Sign In' : 'Confirm & Complete Registration'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
