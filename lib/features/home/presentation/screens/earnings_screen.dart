import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/driver_providers.dart';
import '../../models/earning_model.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _activeTab = 'All';

  @override
  Widget build(BuildContext context) {
    final earningsAsyncValue = ref.watch(driverEarningsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
      ),
      body: earningsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (earnings) {
          // Calculate stats
          double totalEarnings = 0;
          double thisMonthEarnings = 0;
          final now = DateTime.now();
          
          for (var earning in earnings) {
            if (earning.status == 'Received') {
              totalEarnings += earning.amount;
              if (earning.transactionDate.month == now.month && earning.transactionDate.year == now.year) {
                thisMonthEarnings += earning.amount;
              }
            }
          }
          
          final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

          // Filter earnings for list
          List<EarningModel> filteredEarnings = earnings;
          if (_activeTab == 'Received') {
            filteredEarnings = earnings.where((e) => e.status == 'Received').toList();
          } else if (_activeTab == 'Pending') {
            filteredEarnings = earnings.where((e) => e.status == 'Pending').toList();
          }

          return Column(
            children: [
              // Top Stats Card
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'This Month',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(thisMonthEarnings),
                              style: const TextStyle(
                                color: Color(0xFFFFC107),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: const Color(0xFF334155),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Earnings',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(totalEarnings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    _buildTab('All'),
                    const SizedBox(width: 12),
                    _buildTab('Received'),
                    const SizedBox(width: 12),
                    _buildTab('Pending'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Earnings List
              Expanded(
                child: filteredEarnings.isEmpty 
                  ? const Center(child: Text('No earnings to show', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      itemCount: filteredEarnings.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filteredEarnings.length) return const SizedBox(height: 80);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildEarningCard(filteredEarnings[index]),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _activeTab == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFC107) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A1128) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEarningCard(EarningModel earning) {
    final isReceived = earning.status == 'Received';
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final formattedDate = DateFormat('dd MMM yyyy').format(earning.transactionDate);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.description ?? 'Trip Payment',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128)),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormat.format(earning.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isReceived ? const Color(0xFF10B981) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isReceived ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  earning.status,
                  style: TextStyle(
                    color: isReceived ? const Color(0xFF059669) : const Color(0xFFD97706),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
