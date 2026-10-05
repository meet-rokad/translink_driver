import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () async {
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          try {
            final response = await Supabase.instance.client
                .from('partners')
                .select('status')
                .eq('auth_id', user.id)
                .maybeSingle();
                
            final status = response?['status'];
            if (mounted) {
              // If status is NEW, they haven't completed onboarding. Route them to profile setup.
              if (status == 'NEW') {
                context.go('/profile_setup');
              } else {
                context.go('/dashboard');
              }
            }
          } catch (e) {
            if (mounted) context.go('/dashboard');
          }
        } else {
          context.pushReplacement('/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Image.asset(
            'assets/images/logo.png',
            width: 220, // Constrain width so it doesn't become massive
            fit: BoxFit.contain,
          ).animate()
           .fadeIn(duration: 800.ms, curve: Curves.easeOut)
           .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutCubic)
           .shimmer(delay: 800.ms, duration: 1200.ms, color: Colors.grey.withOpacity(0.15)),
        ),
      ),
    );
  }
}


