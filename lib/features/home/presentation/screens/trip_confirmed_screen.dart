import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/primary_button.dart';

class TripConfirmedScreen extends StatelessWidget {
  const TripConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: Color(0xFF10B981),
                    size: 50,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Headings
              const Text(
                'Trip Confirmed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A1128),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'re All Set!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Load assigned successfully',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Ahmedabad', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF0A1128)),
                        ),
                        Text('Rajkot', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('15 Sep 2026', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                        Container(height: 12, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                        const Text('14 Ton', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Color(0xFFE5E7EB)),
                    ),
                    const Text('Shipper: ABC Traders', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Contact: +91 98765 43210', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Buttons
              PrimaryButton(
                text: 'View Trip',
                onPressed: () {
                  context.go('/trips');
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Go to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1128),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
