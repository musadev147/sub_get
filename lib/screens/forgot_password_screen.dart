import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sub_get/theme.dart';

enum ForgotPasswordStage {
  enterEmail,
  verifyOtp,
  resetPassword,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotPasswordStage _stage = ForgotPasswordStage.enterEmail;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // OTP Countdown timer
  Timer? _timer;
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _sendOtp() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _stage = ForgotPasswordStage.verifyOtp;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code sent successfully (Demo OTP: 1234)'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    }
  }

  void _verifyOtp() async {
    if (!_formKeyOtp.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (_otpController.text == '1234') {
        setState(() {
          _stage = ForgotPasswordStage.resetPassword;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP code. Please try "1234"'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetPassword() async {
    if (!_formKeyPassword.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please log in.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      Navigator.pop(context); // Go back to login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStageWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStageWidget() {
    switch (_stage) {
      case ForgotPasswordStage.enterEmail:
        return _buildEnterEmailStage();
      case ForgotPasswordStage.verifyOtp:
        return _buildVerifyOtpStage();
      case ForgotPasswordStage.resetPassword:
        return _buildResetPasswordStage();
    }
  }

  Widget _buildEnterEmailStage() {
    return Column(
      key: const ValueKey('enterEmail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter your registered email address or phone number and we will send you a 4-digit OTP to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKeyEmail,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address or Phone',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'user@gmail.com or 017XXXXXXXX',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter email or phone number';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _buildVerifyOtpStage() {
    return Column(
      key: const ValueKey('verifyOtp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Enter OTP Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a verification code to ${_emailController.text}. Please enter the code below to proceed.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKeyOtp,
          child: TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: '1234',
              hintStyle: TextStyle(color: Colors.white12, fontSize: 22, letterSpacing: 8),
              prefixIcon: Icon(Icons.security),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter OTP';
              if (v.length != 4) return 'OTP must be 4 digits';
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _canResend ? 'Didn\'t get OTP? ' : 'Resend code in ${_secondsLeft}s ',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (_canResend)
              GestureDetector(
                onTap: _isLoading ? null : _sendOtp,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Verify Code'),
        ),
      ],
    );
  }

  Widget _buildResetPasswordStage() {
    return Column(
      key: const ValueKey('resetPassword'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Center(
          child: Icon(
            Icons.lock_open_outlined,
            size: 80,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'New Password',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please create a strong new password that you don\'t use on other services.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKeyPassword,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter new password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your new password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Reset Password'),
        ),
      ],
    );
  }
}
