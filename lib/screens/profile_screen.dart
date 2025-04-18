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
import 'package:url_launcher/url_launcher.dart';
import 'package:mailto/mailto.dart';

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
  bool _showPrivacyPolicy = false;
  bool _showDeleteConfirmation = false;

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

  Future<void> _deleteAccount() async {
    try {
      // Delete all appointments for this user
      final appointments = await _firestore
          .collection('termini')
          .where('userId', isEqualTo: _currentUser.uid)
          .get();

      for (var doc in appointments.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _firestore.collection('users').doc(_currentUser.uid).delete();

      // Delete profile image if exists
      if (_profileImageUrl != null) {
        final ref = FirebaseStorage.instance.refFromURL(_profileImageUrl!);
        await ref.delete();
      }

      // Delete auth user
      await _currentUser.delete();

      // Logout and redirect to login
      _logout(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error deleting account: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchEmail() async {
    final mailtoLink = Mailto(
      to: ['dzeno.brcaninovic@gmail.com'],
      subject: 'SalonTime Support',
    );
    await launchUrl(Uri.parse(mailtoLink.toString()));
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
                        _buildNonEditableField('Ime i prezime', _nameController, Icons.person),
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
                        
                        // Privacy and Security Section
                        const SizedBox(height: 30),
                        const Text(
                          'Privatnost i sigurnost',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF26A69A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildSettingItem(
                          icon: Icons.privacy_tip,
                          title: 'Politika privatnosti',
                          onTap: () {
                            setState(() {
                              _showPrivacyPolicy = !_showPrivacyPolicy;
                            });
                          },
                        ),
                        if (_showPrivacyPolicy)
                          _buildPrivacyPolicyContent(),
                        
                        _buildSettingItem(
                          icon: Icons.mail,
                          title: 'Kontaktirajte nas',
                          onTap: _launchEmail,
                        ),
                        
                        _buildSettingItem(
                          icon: Icons.delete,
                          title: 'Obriši račun',
                          color: Colors.red,
                          onTap: () {
                            setState(() {
                              _showDeleteConfirmation = true;
                            });
                          },
                        ),
                        if (_showDeleteConfirmation)
                          _buildDeleteConfirmation(),
                        
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

  Widget _buildNonEditableField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
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
              hintText: '$label',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
            ),
            enabled: false,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Color color = const Color(0xFF26A69A),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Politika privatnosti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26A69A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ova politika privatnosti odnosi se na aplikaciju SalonTime.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prikupljanje i upotreba podataka',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SalonTime ne prikuplja osobne podatke korisnika bez njihovog znanja. Podaci o rezervacijama klijenata pohranjuju se lokalno ili unutar sigurnih baza podataka, ovisno o implementaciji.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dijeljenje podataka',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ne dijelimo korisničke podatke s trećim stranama. Podaci se koriste isključivo za funkcioniranje aplikacije.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vaša prava',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Korisnici imaju pravo zatražiti brisanje podataka ili dodatne informacije kontaktiranjem nas putem e-maila.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _launchEmail,
            child: const Text(
              'Pošaljite nam e-mail na: dzeno.brcaninovic@gmail.com',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF26A69A),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jeste li sigurni da želite obrisati račun?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ova akcija će trajno obrisati vaš račun i sve povezane podatke. Ova akcija se ne može poništiti.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showDeleteConfirmation = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF26A69A),
                    side: const BorderSide(color: Color(0xFF26A69A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Odustani'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Obriši račun'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}