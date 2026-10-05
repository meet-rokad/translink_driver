import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  final String? returnTo;
  
  const LoginScreen({Key? key, this.returnTo}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = "";
  bool _loading = false;

  void _handleSubmit() async {
    setState(() {
      _error = "";
      _loading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Implement actual login using base44 or your auth provider
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception("Invalid email or password");
      }
      
      // Navigate to returnTo or home
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

  void _handleGoogle() {
    // TODO: Implement Google Sign in
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      icon: Icons.login,
      title: "Welcome back",
      subtitle: "Log in to your account",
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Don't have an account? "),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/register', 
                arguments: widget.returnTo,
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Create one"),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata, size: 24), // Placeholder for Google icon
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Forgot password?", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
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
              : const Text("Log in"),
          ),
        ],
      ),
    );
  }
}
