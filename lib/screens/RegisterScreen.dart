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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  Uint8List? _webImage;
  Uint8List? _compressedImage;
  String? _profileImageUrl;
  String errorMessage = "";
  bool _isImageUploading = false;

  Future<Uint8List?> _compressImage(File file) async {
    try {
      // Prvo provjerimo veličinu originalne slike
      final originalSize = await file.length();

      // Ako je slika manja od 2MB, ne kompresiramo je
      if (originalSize < 2000000) {
        return await file.readAsBytes();
      }

      // Obavijestimo korisnika o optimizaciji
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

      if (result == null) {
        throw Exception('Kompresija nije uspjela');
      }

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
          // Web verzija - čitamo byteove direktno
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _profileImage = File('dummy_path');
          });
          await _uploadImage(bytes);
        } else {
          // Mobile verzija - kompresija slike
          final file = File(pickedFile.path);
          final compressedImage = await _compressImage(file);

          if (compressedImage != null) {
            setState(() {
              _profileImage = file;
              _compressedImage = compressedImage;
            });
            await _uploadImage(compressedImage);
          } else {
            // Ako kompresija ne uspije, uploadaj original
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF26A69A), // Teal
              Color(0xFF80CBC4), // Lighter teal
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Registruj se',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Napravi svoj račun',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          _isImageUploading
                              ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  backgroundImage:
                                      (_webImage != null && kIsWeb)
                                          ? MemoryImage(_webImage!)
                                          : (_profileImage != null)
                                          ? FileImage(_profileImage!)
                                          : null,
                                  child:
                                      (_webImage == null &&
                                              _profileImage == null)
                                          ? Icon(
                                            Icons.camera_alt,
                                            size: 40,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                              ),
                          if ((_webImage != null || _profileImage != null) &&
                              !_isImageUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF26A69A),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
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

                    // Full Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Puno ime i prezime',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _fullNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite vaše ime i prezime',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone Number Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Broj telefona',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _phoneNumberController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite vaš broj telefona',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite vašu email adresu',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Šifra',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite šifru',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Potvrdite šifru',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _confirmPasswordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Potvrdite šifru',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
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

                          User? user = await _authService
                              .registerWithEmailAndPassword(
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
                                            builder:
                                                (context) =>
                                                    const SalonListScreen(),
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
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child:
                            _isImageUploading
                                ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Kreiraj račun',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Already have account link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(text: "Već imate račun? "),
                              TextSpan(
                                text: 'Prijavi se',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
