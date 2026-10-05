import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/primary_button.dart';

class AddLoadScreen extends StatefulWidget {
  const AddLoadScreen({super.key});

  @override
  State<AddLoadScreen> createState() => _AddLoadScreenState();
}

class _AddLoadScreenState extends State<AddLoadScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _materialController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedWeight;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _materialController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submitLoad() {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill From and To locations')),
      );
      return;
    }
    
    // In a real app, save to Firestore here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Load Added Successfully!')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Post a Load',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // From Location
                      const Text(
                        'From (Pickup)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_fromController, 'e.g. Ahmedabad', Icons.location_on_outlined),
                      const SizedBox(height: 20),
                      
                      // To Location
                      const Text(
                        'To (Drop-off)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_toController, 'e.g. Mumbai', Icons.location_on),
                      const SizedBox(height: 20),
                      
                      // Material Type
                      const Text(
                        'Material / Load Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_materialController, 'e.g. Steel, Chemicals, Furniture', Icons.category_outlined),
                      const SizedBox(height: 20),
                      
                      // Weight Required
                      const Text(
                        'Required Vehicle Capacity',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Select Capacity', style: TextStyle(color: Colors.black38, fontSize: 14)),
                            value: _selectedWeight,
                            items: ['9 Ton', '14 Ton', '20 Ton', '24 Ton', '40 Ton'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWeight = value;
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Price (Optional)
                      const Text(
                        'Expected Freight (₹) - Optional',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(_priceController, 'e.g. 15000', Icons.currency_rupee, keyboardType: TextInputType.number),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              PrimaryButton(
                text: 'Post Load',
                onPressed: _submitLoad,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        ),
      ),
    );
  }
}
