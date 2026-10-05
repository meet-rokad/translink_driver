import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';

class RegisterScreen extends StatefulWidget {
  final String? returnTo;
  
  const RegisterScreen({Key? key, this.returnTo}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  String _error = "";
  bool _loading = false;
  bool _showOtp = false;

  void _handleSubmit() async {
    setState(() {
      _error = "";
    });

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _error = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception("Please fill in all fields");
      }

      setState(() {
        _showOtp = true;
      });
    } catch (err) {
      setState(() {
        _error = err.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _handleVerify() async {
    setState(() {
      _error = "";
      _loading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (_otpController.text.length < 6) {
        throw Exception("Invalid OTP code");
      }
      
      // Success, navigate
      if (widget.returnTo != null) {
        Navigator.pushReplacementNamed(context, widget.returnTo!);
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (err) {
      setState(() {
        _error = err.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _handleResend() async {
    setState(() {
      _error = "";
    });
    
    // Simulate API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Check your email for the new code.")),
    );
  }

  void _handleGoogle() {
    // TODO: Implement Google Sign in
  }

  Widget _buildOtpForm() {
    return AuthLayout(
      icon: Icons.mail_outline,
      title: "Verify your email",
      subtitle: "We sent a code to ${_emailController.text}",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(
              hintText: "••••••",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
              counterText: "",
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _handleVerify,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Text("Verify"),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Didn't receive the code? "),
              TextButton(
                onPressed: _handleResend,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Resend"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return AuthLayout(
      icon: Icons.person_add_outlined,
      title: "Create your account",
      subtitle: "Sign up to get started",
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account? "),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context, 
                '/login', 
                arguments: widget.returnTo,
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Log in"),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text("Continue with Google"),
            onPressed: _handleGoogle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "OR",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text("Email", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail_outline),
              hintText: "you@example.com",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: "••••••••",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: "••••••••",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _loading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Text("Create account"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOtp) {
      return _buildOtpForm();
    }
    return _buildRegisterForm();
  }
}
