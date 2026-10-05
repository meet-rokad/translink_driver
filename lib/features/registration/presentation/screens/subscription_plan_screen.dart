import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/primary_button.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  String _selectedPlan = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0A1128)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Choose Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A1128),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 3 of 3 — Select a Plan',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanCard(
                        title: 'Monthly',
                        price: '₹ 999',
                        subtitle: 'Best for individuals',
                        isSelected: _selectedPlan == 'Monthly',
                        onTap: () => setState(() => _selectedPlan = 'Monthly'),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildPlanCard(
                        title: 'Quarterly',
                        price: '₹ 2,499',
                        tagText: 'Save 17%',
                        tagColor: const Color(0xFFE0F2FE),
                        tagTextColor: const Color(0xFF0284C7),
                        isSelected: _selectedPlan == 'Quarterly',
                        onTap: () => setState(() => _selectedPlan = 'Quarterly'),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildPlanCard(
                        title: 'Yearly',
                        price: '₹ 7,999',
                        tagText: 'Save 33%',
                        tagColor: const Color(0xFFDCFCE7),
                        tagTextColor: const Color(0xFF16A34A),
                        isSelected: _selectedPlan == 'Yearly',
                        onTap: () => setState(() => _selectedPlan = 'Yearly'),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildFeatureRow('Access to verified loads'),
                      const SizedBox(height: 12),
                      _buildFeatureRow('Direct contact with shippers'),
                      const SizedBox(height: 12),
                      _buildFeatureRow('No commission on trips'),
                      const SizedBox(height: 12),
                      _buildFeatureRow('Priority support'),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              PrimaryButton(
                text: 'Subscribe Now',
                onPressed: () {
                  context.go('/dashboard'); 
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? subtitle,
    String? tagText,
    Color? tagColor,
    Color? tagTextColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFFFFDF5) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1128),
                      ),
                    ),
                    if (tagText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tagText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0A1128),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ]
              ],
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Row(
      children: [
        const Icon(Icons.check, color: Color(0xFF10B981), size: 18),
        const SizedBox(width: 12),
        Text(
          feature,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0A1128), 
          ),
        ),
      ],
    );
  }
}
