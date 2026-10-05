import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../profile/repositories/partner_repository.dart';
import '../../../profile/models/partner_document_model.dart';
import '../../../profile/models/truck_document_model.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  bool _isLoading = false;
  
  final Map<String, bool> _uploadedDocs = {
    'Aadhaar': false,
    'Driving Licence': false,
    'RC': false,
    'PUC': false,
    'Fitness Certificate': false,
    'Insurance': false,
  };
  final Map<String, XFile> _docFiles = {};

  Future<void> _pickDocument(String docName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (pickedFile != null) {
      // Validate the file extension to ensure it is an image
      final ext = pickedFile.path.split('.').last.toLowerCase();
      if (ext != 'jpg' && ext != 'jpeg' && ext != 'png' && ext != 'pdf') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a valid Image or PDF format only')),
        );
        return;
      }

      setState(() {
        _uploadedDocs[docName] = true;
        _docFiles[docName] = pickedFile;
      });
    }
  }

  Future<String?> _uploadToSupabase(String docName, XFile file, String uid) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$uid/$docName/$fileName';
      
      await Supabase.instance.client.storage.from('documents').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      return Supabase.instance.client.storage.from('documents').getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading $docName: $e');
      return null;
    }
  }

  Future<void> _submitDocuments() async {
    if (!_uploadedDocs.values.every((uploaded) => uploaded)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents in valid formats')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final uid = user!.id;
      
      final partnerResponse = await Supabase.instance.client
          .from('partners')
          .select('id')
          .eq('auth_id', uid)
          .maybeSingle();
          
      if (partnerResponse != null && partnerResponse['id'] != null) {
        final partnerIdStr = partnerResponse['id'].toString();
        
        final truckResponse = await Supabase.instance.client
            .from('trucks')
            .select('id')
            .eq('partner_id', partnerIdStr)
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
        if (truckResponse == null || truckResponse['id'] == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: No active truck found. Please add a vehicle first.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        
        final truckIdStr = truckResponse['id'].toString();

        // Upload and save each document
        for (final entry in _docFiles.entries) {
          final docName = entry.key;
          final file = entry.value;
          
          final fileUrl = await _uploadToSupabase(docName, file, uid);
          if (fileUrl != null) {
            final docData = {
              'partner_id': partnerIdStr,
              'document_type': docName,
              'file_url': fileUrl,
            };
            if (docName != 'Aadhaar' && docName != 'Driving Licence') {
              docData['truck_id'] = truckIdStr;
            }
            await Supabase.instance.client.from('documents').insert(docData);
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Documents submitted for verification!')),
          );
          context.go('/onboarding_payment');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Partner profile not found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0A1128), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Upload Documents',
          style: TextStyle(color: Color(0xFF0A1128), fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 3 of 3 — Verification',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your documents in Image or PDF format. Our system will strictly verify the formats.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partner Documents',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 16),
                      _buildDocCard('Aadhaar Card', 'Aadhaar'),
                      const SizedBox(height: 12),
                      _buildDocCard('Driving Licence', 'Driving Licence'),
                      
                      const SizedBox(height: 32),
                      
                      const Text(
                        'Truck Documents',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A1128)),
                      ),
                      const SizedBox(height: 16),
                      _buildDocCard('RC Book', 'RC'),
                      const SizedBox(height: 12),
                      _buildDocCard('PUC Certificate', 'PUC'),
                      const SizedBox(height: 12),
                      _buildDocCard('Fitness Certificate', 'Fitness Certificate'),
                      const SizedBox(height: 12),
                      _buildDocCard('Vehicle Insurance', 'Insurance'),
                    ],
                  ),
                ),
              ),
              
              _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : PrimaryButton(
                    text: 'Submit Documents',
                    onPressed: _submitDocuments,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard(String title, String docKey) {
    bool isUploaded = _uploadedDocs[docKey] ?? false;
    
    return InkWell(
      onTap: () => _pickDocument(docKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isUploaded ? const Color(0xFF10B981) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: isUploaded ? const Color(0xFFECFDF5) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUploaded ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUploaded ? Icons.check : Icons.upload_file,
                color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0A1128)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded ? 'Uploaded successfully' : 'Tap to upload Image/PDF',
                    style: TextStyle(
                      color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}




