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

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _isImageUploading = true;
        });

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _profileImage = File('dummy_path');
          });
          await _uploadImage(bytes);
        } else {
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
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = 'profile_images/$fileName';

      final ref = FirebaseStorage.instance.ref(destination);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (kIsWeb && webImage != null) {
        await ref.putData(webImage, metadata);
      } else if (_profileImage != null) {
        await ref.putFile(_profileImage!, metadata);
      } else {
        throw Exception('No image selected');
      }

      final downloadUrl = await ref.getDownloadURL();

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
      await _firestore.collection('users').doc(_currentUser.uid).update({
        'fullName': _nameController.text,
        'phoneNumber': _phoneController.text,
      });

      if (_emailController.text != _currentUser.email) {
        await _currentUser.updateEmail(_emailController.text);
      }

      if (_passwordController.text.isNotEmpty) {
        await _currentUser.updatePassword(_passwordController.text);
      }

      setState(() {
        _isEditing = false;
        _errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text('Moj Profil'),
        backgroundColor: const Color(0xFF26A69A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
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
                                      backgroundColor: const Color(0xFF26A69A).withOpacity(0.2),
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
                        const SizedBox(height: 30),
                        _buildEditableField('Ime i prezime', _nameController, Icons.person),
                        const SizedBox(height: 20),
                        _buildEditableField('Email', _emailController, Icons.email),
                        const SizedBox(height: 20),
                        _buildEditableField('Broj telefona', _phoneController, Icons.phone),
                        const SizedBox(height: 20),
                        if (_isEditing)
                          _buildEditableField(
                            'Nova lozinka',
                            _passwordController,
                            Icons.lock,
                            isPassword: true,
                          ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _logout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Odjava',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF26A69A),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Unesite $label',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: const Icon(Icons.visibility_off, color: Color(0xFF26A69A)),
                      onPressed: () {},
                    )
                  : null,
            ),
            obscureText: isPassword,
            enabled: _isEditing,
            keyboardType:
                label == 'Broj telefona' ? TextInputType.phone : TextInputType.text,
          ),
        ],
      ),
    );
  }
}