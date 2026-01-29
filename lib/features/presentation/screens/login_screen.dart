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
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _fullNameController.text.isEmpty ? null : _fullNameController.text,
      );
    } else {
      await ref.read(authProvider.notifier).signIn(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    // Show error if exists
    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: AppColors.error,
          ),
        );
      });
    }
    
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
                
                // Username
                CustomTextField(
                  controller: _usernameController,
                  label: _isSignUp ? 'Username' : 'Username or Email',
                  hint: _isSignUp ? 'Enter username' : 'Enter username or email',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
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
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
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
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Submit Button
                CustomButton(
                  text: _isSignUp ? 'Sign Up' : 'Sign In',
                  onPressed: _submit,
                  isLoading: authState.isLoading,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Toggle Sign In/Sign Up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _formKey.currentState?.reset();
                    });
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}