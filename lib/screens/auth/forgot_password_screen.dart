import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/electric_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  String? _serverStatus;

  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = 60);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
      } else {
        setState(() => _resendSecondsRemaining--);
      }
    });
  }

  Future<void> _handleSendCode({bool isResend = false}) async {
    if (!isResend && !_formKey.currentState!.validate()) return;
    if (isResend && !_emailController.text.contains('@')) return;

    setState(() {
      _isLoading = true;
      _serverStatus = null;
    });

    try {
      final message = await _authService.requestPasswordReset(
        email: _emailController.text,
        onStatusChange: (status) {
          if (mounted) setState(() => _serverStatus = status);
        },
      );
      if (!mounted) return;
      setState(() => _codeSent = true);
      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _serverStatus = null;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _serverStatus = null;
    });

    try {
      final message = await _authService.resetPassword(
        email: _emailController.text,
        resetCode: _codeController.text,
        newPassword: _newPasswordController.text,
        onStatusChange: (status) {
          if (mounted) setState(() => _serverStatus = status);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _serverStatus = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recover Password'),
        backgroundColor: EleesaColors.deepNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircuitGridHeader(
                      title: _codeSent ? 'Verify Recovery Pulse' : 'Reset Portal Access',
                      subtitle: _codeSent
                          ? 'Enter the 6-digit code sent to your inbox and set a new password.'
                          : 'Enter your registered ELEESA email to dispatch a 6-digit recovery code.',
                      isStepTwo: _codeSent,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_codeSent && !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Account Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email address'
                          : null,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      child: !_codeSent
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              _resendTimer?.cancel();
                                              setState(() {
                                                _codeSent = false;
                                                _resendSecondsRemaining = 0;
                                                _codeController.clear();
                                                _newPasswordController.clear();
                                              });
                                            },
                                      child: const Text('Change email'),
                                    ),
                                    TextButton(
                                      onPressed: (_isLoading || _resendSecondsRemaining > 0)
                                          ? null
                                          : () => _handleSendCode(isResend: true),
                                      child: Text(
                                        _resendSecondsRemaining > 0
                                            ? 'Resend code in ${_resendSecondsRemaining}s'
                                            : 'Resend Code',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _resendSecondsRemaining > 0
                                              ? Colors.grey
                                              : EleesaColors.slateBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _codeController,
                                  enabled: !_isLoading,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    labelText: '6-Digit Recovery Code',
                                    counterText: '',
                                    prefixIcon: const Icon(Icons.pin_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().length < 6)
                                      ? 'Enter the 6-digit code'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _newPasswordController,
                                  enabled: !_isLoading,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Minimum 6 characters required'
                                      : null,
                                ),
                              ],
                            ),
                    ),
                    ColdStartStatusBanner(statusMessage: _serverStatus),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : (_codeSent ? _handleResetPassword : () => _handleSendCode()),
                      style: FilledButton.styleFrom(
                        backgroundColor: EleesaColors.deepNavy,
                        foregroundColor: EleesaColors.electricCyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: EleesaColors.electricCyan,
                              ),
                            )
                          : Text(
                              _codeSent ? 'Reset Password' : 'Send Recovery Code',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}