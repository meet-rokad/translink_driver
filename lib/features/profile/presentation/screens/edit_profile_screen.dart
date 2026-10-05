import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  String? _selectedCity;
  
  bool _isLoading = false;
  bool _isFetching = true;

  Uint8List? _imageBytes;
  XFile? _profileImage;
  String? _existingProfileUrl;
  String? _partnerId;

  final List<String> _cities = ['Ahmedabad', 'Surat', 'Rajkot', 'Vadodara'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('partners')
            .select()
            .eq('auth_id', user.id)
            .maybeSingle();
            
        if (response != null) {
          _partnerId = user.id; // use auth_id
          _nameController.text = response['full_name'] ?? response['owner_name'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['mobile_number'] ?? '';
          _selectedGender = response['gender'];
          _selectedCity = response['city'];
          _existingProfileUrl = response['profile_photo_url'] ?? response['profile_pic'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      setState(() {
        _isFetching = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isEmpty || email.isEmpty || phone.isEmpty || _selectedGender == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user != null && _partnerId != null) {
        String? imageUrl = _existingProfileUrl;

        // Upload image to Supabase Storage if picked
        if (_profileImage != null && _imageBytes != null) {
          try {
            final fileExt = _profileImage!.path.split('.').last;
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            final filePath = 'profile_pics/${user.id}/$fileName';
            
            await Supabase.instance.client.storage
                .from('profiles')
                .uploadBinary(filePath, _imageBytes!);
                
            imageUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(filePath);
          } catch (e) {
            print('Image upload failed: $e');
          }
        }
        
        await Supabase.instance.client.from('partners').update({
          'full_name': name,
          'email': email,
          // Mobile number is not updated since it's the verified login number
          'gender': _selectedGender,
          'city': _selectedCity,
          if (imageUrl != null) 'profile_photo_url': imageUrl,
        }).eq('auth_id', user.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          context.pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0A1128),
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
        : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                  color: const Color(0xFFF9FAFB),
                                  image: _imageBytes != null
                                      ? DecorationImage(
                                          image: MemoryImage(_imageBytes!),
                                          fit: BoxFit.cover,
                                        )
                                      : _existingProfileUrl != null && _existingProfileUrl!.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(_existingProfileUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: (_imageBytes == null && (_existingProfileUrl == null || _existingProfileUrl!.isEmpty))
                                    ? const Icon(Icons.person_outline, size: 50, color: Color(0xFF6B7280))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFC107),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Color(0xFF0A1128), size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Email
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'e.g. ramesh@gmail.com',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone Number
                      const Text(
                        'Mobile Number',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          readOnly: true, // Make it read-only
                          decoration: const InputDecoration(
                            hintText: '10-digit Mobile Number',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Color(0xFFF3F4F6), // Grey out to indicate it's not editable
                            counterText: '',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 14),
                              child: Text('+91 ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Gender
                      const Text(
                        'Gender',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedGender = 'Male'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Male' ? const Color(0xFFFFC107) : Colors.white,
                                  border: Border.all(color: _selectedGender == 'Male' ? const Color(0xFFFFC107) : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text('Male', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedGender == 'Male' ? Colors.black : Colors.black54))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedGender = 'Female'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'Female' ? const Color(0xFFFFC107) : Colors.white,
                                  border: Border.all(color: _selectedGender == 'Female' ? const Color(0xFFFFC107) : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text('Female', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedGender == 'Female' ? Colors.black : Colors.black54))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // City
                      const Text(
                        'City',
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
                            value: _selectedCity,
                            isExpanded: true,
                            hint: const Text('Select City', style: TextStyle(color: Colors.black38, fontSize: 14)),
                            items: _cities.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                              });
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280), size: 20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                  : PrimaryButton(
                      text: 'Save Changes',
                      onPressed: _updateProfile,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}



