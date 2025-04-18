import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:frizerski_salon/screens/SalonList.dart';
import 'AuthService.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  Uint8List? _webImage;
  Uint8List? _compressedImage;
  String? _profileImageUrl;
  String errorMessage = "";
  bool _isImageUploading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<Uint8List?> _compressImage(File file) async {
    try {
      final originalSize = await file.length();
      if (originalSize < 2000000) {
        return await file.readAsBytes();
      }

      if (originalSize > 5000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Optimiziramo vašu sliku za brži upload...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: originalSize > 5000000 ? 720 : 1080,
        minHeight: originalSize > 5000000 ? 720 : 1080,
        quality: originalSize > 10000000 ? 75 : 85,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
      );

      return result;
    } catch (e) {
      print('Greška pri kompresiji slike: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() {
          _isImageUploading = true;
          errorMessage = "";
        });

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _profileImage = File('dummy_path');
          });
          await _uploadImage(bytes);
        } else {
          final file = File(pickedFile.path);
          final compressedImage = await _compressImage(file);

          if (compressedImage != null) {
            setState(() {
              _profileImage = file;
              _compressedImage = compressedImage;
            });
            await _uploadImage(compressedImage);
          } else {
            await _uploadImage(await file.readAsBytes());
          }
        }
      }
    } catch (e) {
      print('Greška pri odabiru slike: $e');
      setState(() {
        errorMessage = "Greška pri odabiru slike";
        _isImageUploading = false;
      });
    }
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destination = 'profile_images/$fileName';

      final ref = FirebaseStorage.instance.ref(destination);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      await ref.putData(imageBytes, metadata);
      _profileImageUrl = await ref.getDownloadURL();

      setState(() {
        _isImageUploading = false;
      });
    } catch (e) {
      print('Greška pri uploadu slike: $e');
      setState(() {
        errorMessage = "Greška pri uploadu slike";
        _isImageUploading = false;
      });
    }
  }

  Future<void> _sendEmailVerification(User user) async {
    await user.sendEmailVerification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              Text(
                'Kreiraj račun',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Popunite podatke za registraciju',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Profile Picture Section
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.teal.shade200,
                          width: 2,
                        ),
                      ),
                      child: _isImageUploading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Colors.teal.shade400,
                              ),
                            )
                          : GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage:
                                    (_webImage != null && kIsWeb)
                                        ? MemoryImage(_webImage!)
                                        : (_profileImage != null)
                                            ? FileImage(_profileImage!)
                                            : null,
                                child: (_webImage == null && _profileImage == null)
                                    ? Icon(
                                        Icons.camera_alt_outlined,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      )
                                    : null,
                              ),
                            ),
                    ),
                    if ((_webImage != null || _profileImage != null) && !_isImageUploading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Puno ime i prezime',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Broj telefona',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email adresa',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Šifra',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Potvrdite šifru',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 24),

              if (errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (errorMessage.isNotEmpty) const SizedBox(height: 16),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_passwordController.text != _confirmPasswordController.text) {
                      setState(() {
                        errorMessage = "Lozinke se ne podudaraju!";
                      });
                      return;
                    }

                    if (_fullNameController.text.isEmpty) {
                      setState(() {
                        errorMessage = "Unesite vaše ime i prezime!";
                      });
                      return;
                    }

                    setState(() {
                      _isImageUploading = true;
                    });

                    User? user = await _authService.registerWithEmailAndPassword(
                      _emailController.text,
                      _passwordController.text,
                      _fullNameController.text,
                      _phoneNumberController.text,
                      profileImageUrl: _profileImageUrl,
                    );

                    setState(() {
                      _isImageUploading = false;
                    });

                    if (user != null) {
                      await _sendEmailVerification(user);

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Verifikacija emaila'),
                            content: Text(
                              'Poslali smo vam email za verifikaciju. Molimo vas da provjerite svoj inbox i verifikujte email prije nego što se prijavite.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SalonListScreen(),
                                    ),
                                  );
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      setState(() {
                        errorMessage = "Registracija nije uspjela!";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isImageUploading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Registruj se',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

            
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        const TextSpan(text: "Već imate račun? "),
                        TextSpan(
                          text: 'Prijavite se',
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}