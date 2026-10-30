// lib/screens/login_screen.dart
// ─────────────────────────────
// Sign in (mobile + PIN) / Create account (name, mobile, PIN, confirm PIN),

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl    = TextEditingController();
  final _pin2Ctrl   = TextEditingController();

  bool    _isRegister = false;
  bool    _obscure    = true;
  bool    _busy       = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });

    try {
      final auth = AuthService.instance;
      if (_isRegister) {
        await auth.register(
          name: _nameCtrl.text,
          mobile: _mobileCtrl.text,
          pin: _pinCtrl.text,
        );
      } else {
        await auth.login(mobile: _mobileCtrl.text, pin: _pinCtrl.text);
      }
      // AuthGate swaps to HomeScreen on its own.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
      _pinCtrl.clear();
      _pin2Ctrl.clear();
    });
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required TextInputAction action,
    VoidCallback? onSubmit,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      obscureText: _obscure,
      keyboardType: TextInputType.number,
      textInputAction: action,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      onFieldSubmitted: (_) => onSubmit?.call(),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eye = IconButton(
      tooltip: _obscure ? 'Show PIN' : 'Hide PIN',
      icon: Icon(_obscure
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/app_logo_full.png', height: 140),
                    const SizedBox(height: 16),
                    Text(
                      _isRegister ? 'Create your account' : 'Sign in',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegister
                          ? 'Your rice field scans are saved under your mobile number.'
                          : 'Enter your mobile number and PIN to see your scan history.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // 1. Full name (register only)
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        enabled: !_busy,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2. Mobile number
                    TextFormField(
                      controller: _mobileCtrl,
                      enabled: !_busy,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        hintText: '09171234567',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      AuthService.normalizeMobile(v ?? '') == null
                          ? 'Enter a valid mobile number'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // 3. PIN
                    _pinField(
                      controller: _pinCtrl,
                      label: '4-digit PIN',
                      action: _isRegister
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmit: _isRegister ? null : _submit,
                      suffix: eye,
                      validator: (v) => (v == null || v.length != 4)
                          ? 'PIN must be 4 digits'
                          : null,
                    ),

                    // 4. Confirm PIN (register only)
                    if (_isRegister) ...[
                      const SizedBox(height: 14),
                      _pinField(
                        controller: _pin2Ctrl,
                        label: 'Confirm PIN',
                        action: TextInputAction.done,
                        onSubmit: _submit,
                        validator: (v) =>
                        v != _pinCtrl.text ? 'PINs do not match' : null,
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _showForgotPasswordModal,
                          child: const Text(
                            'Forgot PIN / Password?',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _busy
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Text(_isRegister ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _toggleMode,
                      child: Text(
                        _isRegister
                            ? 'Already registered? Sign in'
                            : 'New here? Create account',
                        style: const TextStyle(color: AppTheme.primary),
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

  void _showForgotPasswordModal() {
    final resetMobileCtrl = TextEditingController(text: _mobileCtrl.text);
    final resetPinCtrl = TextEditingController();
    final resetPin2Ctrl = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();
    bool resetObscure = true;
    bool resetBusy = false;
    String? resetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: resetFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reset PIN / Forgot Password',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your mobile number and set a new 4-digit PIN.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: resetMobileCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                          LengthLimitingTextInputFormatter(16),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          hintText: '09171234567',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            AuthService.normalizeMobile(v ?? '') == null
                                ? 'Enter a valid mobile number'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: resetPinCtrl,
                        obscureText: resetObscure,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          labelText: 'New 4-digit PIN',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(resetObscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setModalState(() => resetObscure = !resetObscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length != 4)
                            ? 'PIN must be 4 digits'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: resetPin2Ctrl,
                        obscureText: resetObscure,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Confirm New 4-digit PIN',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v != resetPinCtrl.text
                            ? 'PINs do not match'
                            : null,
                      ),
                      if (resetError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          resetError!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: resetBusy
                            ? null
                            : () async {
                                if (!resetFormKey.currentState!.validate()) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(context);
                                setModalState(() {
                                  resetBusy = true;
                                  resetError = null;
                                });
                                try {
                                  await AuthService.instance.resetPin(
                                    mobile: resetMobileCtrl.text,
                                    newPin: resetPinCtrl.text,
                                  );
                                  if (mounted) {
                                    nav.pop();
                                    setState(() {
                                      _mobileCtrl.text = resetMobileCtrl.text;
                                      _pinCtrl.text = resetPinCtrl.text;
                                    });
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('PIN successfully reset! You can now sign in.'),
                                        backgroundColor: AppTheme.primary,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    resetError = e.toString();
                                    resetBusy = false;
                                  });
                                }
                              },
                        child: resetBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Reset PIN'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}