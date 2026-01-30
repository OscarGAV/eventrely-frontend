import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/configuration/app_config.dart';
import '../../presentation/providers.dart';
import '../../presentation/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _obscurePassword = true;
  
  // Variable para controlar si ya mostramos el error
  String? _lastShownError;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }
  
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isSignUp) {
      await ref.read(authProvider.notifier).signUp(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
      );
    } else {
      await ref.read(authProvider.notifier).signIn(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Mostrar error solo si es nuevo y no lo hemos mostrado antes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != _lastShownError) {
        _lastShownError = next.error;
        
        // Mostrar SnackBar con el error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        next.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        });
      }
      
      // Limpiar el último error mostrado cuando cambiamos de modo
      if (previous?.error != null && next.error == null) {
        _lastShownError = null;
      }
    });
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                
                // Logo/Title
                const Icon(
                  Icons.notifications_active,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isSignUp
                      ? 'Sign up to get started'
                      : 'Sign in to continue',
                  style: AppTextStyles.bodySecondary,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Mostrar error persistente (opcional, además del SnackBar)
                if (authState.error != null && !authState.isLoading) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Username
                CustomTextField(
                  controller: _usernameController,
                  label: _isSignUp ? 'Username' : 'Username or Email',
                  hint: _isSignUp ? 'Enter username' : 'Enter username or email',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    if (_isSignUp && value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Email (only for sign up)
                if (_isSignUp) ...[
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      // Validación básica de email
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Full Name (optional for sign up)
                if (_isSignUp) ...[
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Full Name (Optional)',
                    hint: 'Enter your full name',
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (_isSignUp && value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (_isSignUp && !RegExp(r'[A-Za-z]').hasMatch(value)) {
                      return 'Password must contain at least one letter';
                    }
                    if (_isSignUp && !RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Password must contain at least one number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Submit Button
                CustomButton(
                  text: _isSignUp ? 'Sign Up' : 'Sign In',
                  onPressed: authState.isLoading ? null : _submit,
                  isLoading: authState.isLoading,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Toggle Sign In/Sign Up
                TextButton(
                  onPressed: authState.isLoading ? null : () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _formKey.currentState?.reset();
                      _lastShownError = null; // Reset error tracking
                    });
                    // Limpiar campos al cambiar
                    _usernameController.clear();
                    _passwordController.clear();
                    _emailController.clear();
                    _fullNameController.clear();
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : "Don't have an account? Sign Up",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                
                // Version info (opcional)
                const SizedBox(height: AppSpacing.lg),
                const Center(
                  child: Text(
                    'EventRELY v0.1.0',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}