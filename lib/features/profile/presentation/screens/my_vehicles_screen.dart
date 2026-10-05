import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/partner_repository.dart';
import '../../models/truck_model.dart';

// Provide the list of trucks
final partnerTrucksProvider = FutureProvider.autoDispose<List<Truck>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  final repo = ref.read(partnerRepositoryProvider);
  return repo.getPartnerTrucks(user.id);
});

class MyVehiclesScreen extends ConsumerWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trucksAsyncValue = ref.watch(partnerTrucksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Vehicles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: trucksAsyncValue.maybeWhen(
        data: (trucks) {
          if (trucks.isEmpty) {
            return FloatingActionButton(
              onPressed: () async {
                await context.push('/add_vehicle');
                ref.invalidate(partnerTrucksProvider);
              },
              backgroundColor: const Color(0xFFFFC107),
              child: const Icon(Icons.add, color: Color(0xFF0A1128)),
            );
          }
          return null; // Hide FAB if they already have a truck
        },
        orElse: () => null,
      ),
      body: SafeArea(
        child: trucksAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (trucks) {
            if (trucks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No Vehicles Found',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1128)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add a vehicle to start finding loads',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(partnerTrucksProvider);
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                itemCount: trucks.length,
                itemBuilder: (context, index) {
                  final truck = trucks[index];
                  return _buildVehicleCard(truck);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Truck truck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0A1128)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truck.truckNumber,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${truck.vehicleType ?? 'N/A'} • ${truck.capacity?.toString() ?? 'N/A'} Ton',
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              if (truck.isActive ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Documents Uploaded', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              Row(
                children: const [
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 4),
                  Text('RC Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 4),
                  Text('Insurance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
