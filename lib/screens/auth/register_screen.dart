import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure        = true;
  bool _obscureConfirm = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      name:     _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim().toLowerCase(),
      email:    _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Registration failed'),
        backgroundColor: AppTheme.accentWarm,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Create account',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 30,
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Join Chatter and start messaging',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),

                  const SizedBox(height: 36),

                  // Full name
                  const AuthLabel('Full Name'),
                  const SizedBox(height: 8),
                  AuthField(
                    controller: _nameCtrl,
                    hint: 'Alex Johnson',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Name is required';
                      if (v.trim().length < 2) return 'At least 2 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Username
                  const AuthLabel('Username'),
                  const SizedBox(height: 8),
                  AuthField(
                    controller: _usernameCtrl,
                    hint: 'alexj',
                    icon: Icons.alternate_email,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Username is required';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return 'Only letters, numbers, underscores';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Email
                  const AuthLabel('Email'),
                  const SizedBox(height: 8),
                  AuthField(
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password
                  const AuthLabel('Password'),
                  const SizedBox(height: 8),
                  AuthField(
                    controller: _passwordCtrl,
                    hint: 'Min. 8 characters',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Confirm password
                  const AuthLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  AuthField(
                    controller: _confirmCtrl,
                    hint: 'Re-enter password',
                    icon: Icons.lock_outline,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                        children: [
                          TextSpan(text: 'By signing up you agree to our '),
                          TextSpan(text: 'Terms of Service',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  AuthSubmitButton(
                    label: 'Create Account',
                    loading: auth.loading,
                    onTap: _submit,
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Sign In',
                          style: TextStyle(color: AppTheme.primary, fontSize: 14,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
