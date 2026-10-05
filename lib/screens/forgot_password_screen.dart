import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  void _handleSubmit() async {
    setState(() {
      _loading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (_emailController.text.isEmpty) {
        throw Exception("Please enter your email");
      }
      
    } catch (e) {
      // Always show success regardless in the react code
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _sent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      icon: Icons.mail_outline,
      title: "Reset password",
      subtitle: "We'll send you a link to reset it",
      footer: TextButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        icon: const Icon(Icons.arrow_back, size: 16),
        label: const Text("Back to log in"),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: _sent 
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "If an account exists with that email, you'll receive a password reset link shortly.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Email address", style: TextStyle(fontWeight: FontWeight.w500)),
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
                  : const Text("Send reset link"),
              ),
            ],
          ),
    );
  }
}
