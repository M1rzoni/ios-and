import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frizerski_salon/screens/login_screen.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  late User _currentUser;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  File? _profileImage;
  Uint8List? _webImage;
  String? _profileImageUrl;
  bool _isEditing = false;
  bool _isImageUploading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['fullName'] ?? '';
          _emailController.text = _currentUser.email ?? '';
          _phoneController.text = userDoc['phoneNumber'] ?? '';
          _profileImageUrl = userDoc['profileImageUrl'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _isImageUploading = true;
        });

        if (kIsWeb) {
          // Web verzija - čitamo byteove direktno
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _profileImage = File('dummy_path'); // Placeholder za web
          });
          await _uploadImage(bytes);
        } else {
          // Mobile verzija - koristimo File
          setState(() {
            _profileImage = File(pickedFile.path);
          });
          await _uploadImage();
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = "Error selecting image";
        _isImageUploading = false;
      });
    }
  }

  Future<void> _uploadImage([Uint8List? webImage]) async {
    try {
      // Kreiraj jedinstveni naziv fajla
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = 'profile_images/$fileName';

      final ref = FirebaseStorage.instance.ref(destination);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload različito za web i mobile
      if (kIsWeb && webImage != null) {
        await ref.putData(webImage, metadata);
      } else if (_profileImage != null) {
        await ref.putFile(_profileImage!, metadata);
      } else {
        throw Exception('No image selected');
      }

      // Dobijanje download URL-a
      final downloadUrl = await ref.getDownloadURL();

      // Ažuriranje u Firestore
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
        _isImageUploading = false;
      });
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _errorMessage = "Error uploading profile image";
        _isImageUploading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      // Update name and phone in Firestore
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'fullName': _nameController.text,
        'phoneNumber': _phoneController.text,
      });

      // Update email in Firebase Auth if changed
      if (_emailController.text != _currentUser.email) {
        await _currentUser.updateEmail(_emailController.text);
      }

      // Update password if not empty
      if (_passwordController.text.isNotEmpty) {
        await _currentUser.updatePassword(_passwordController.text);
      }

      setState(() {
        _isEditing = false;
        _errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF26A69A),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  _isImageUploading
                      ? Container(
                        width: 100,
                        height: 100,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF26A69A),
                          ),
                        ),
                      )
                      : GestureDetector(
                        onTap: _isEditing ? _pickImage : null,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(
                            0xFF26A69A,
                          ).withOpacity(0.2),
                          backgroundImage:
                              (_webImage != null && kIsWeb)
                                  ? MemoryImage(_webImage!)
                                  : (_profileImage != null
                                      ? FileImage(_profileImage!)
                                      : (_profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                          : null)),
                          child:
                              _profileImage == null && _profileImageUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF26A69A),
                                  )
                                  : null,
                        ),
                      ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF26A69A),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField('Full Name', _nameController, Icons.person),
            _buildEditableField('Email', _emailController, Icons.email),
            _buildEditableField('Phone Number', _phoneController, Icons.phone),
            if (_isEditing)
              _buildEditableField(
                'New Password',
                _passwordController,
                Icons.lock,
                isPassword: true,
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          enabled: _isEditing,
          suffixIcon: isPassword ? const Icon(Icons.visibility_off) : null,
        ),
        obscureText: isPassword,
        keyboardType:
            label == 'Phone Number' ? TextInputType.phone : TextInputType.text,
      ),
    );
  }
}
