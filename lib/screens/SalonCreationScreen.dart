import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'SalonListAdmin.dart'; // Import the SalonListScreen

class SalonCreationScreen extends StatefulWidget {
  final String salonId;
  final Map<String, dynamic> initialData;

  const SalonCreationScreen({
    super.key,
    this.salonId = '', // Default value for salonId
    this.initialData = const {}, // Default value for initialData
  });

  @override
  _SalonCreationScreenState createState() => _SalonCreationScreenState();
}

class _SalonCreationScreenState extends State<SalonCreationScreen> {
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _workersController = TextEditingController();
  final TextEditingController _vlasnikController = TextEditingController();

  // Variables for working days and hours
  List<String> _selectedWorkingDays = [];
  TimeOfDay _openingTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = TimeOfDay(hour: 18, minute: 0);

  // List of days for the dropdown
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  XFile? _pickedImage; // Use XFile instead of File for web compatibility
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
        print('Image picked: ${_pickedImage!.path}'); // Debug log
      } else {
        print('No image selected'); // Debug log
      }
    } catch (e) {
      print('Error picking image: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) {
      print('No image selected'); // Debug log
      return null;
    }

    try {
      print('Starting image upload...'); // Debug log

      // Create a reference to the Firebase Storage location
      final storageRef = FirebaseStorage.instance.ref().child(
        'salon_logos/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Upload the image
      if (kIsWeb) {
        print('Uploading image for web...'); // Debug log
        final bytes = await _pickedImage!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        print('Uploading image for mobile...'); // Debug log
        final file = File(_pickedImage!.path);
        await storageRef.putFile(file);
      }

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();
      print('Image uploaded successfully. URL: $downloadURL'); // Debug log

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields if initialData is provided
    if (widget.initialData.isNotEmpty) {
      _salonNameController.text = widget.initialData['naziv'] ?? '';
      _addressController.text = widget.initialData['adresa'] ?? '';
      _phoneNumberController.text = widget.initialData['brojTelefona'] ?? '';
      _workersController.text =
          (widget.initialData['radnici'] as List<dynamic>?)?.join(', ') ?? '';
      _vlasnikController.text = widget.initialData['vlasnik'] ?? '';

      // Handle working days
      if (widget.initialData['workingDays'] != null) {
        _selectedWorkingDays = List<String>.from(
          widget.initialData['workingDays'],
        );
      }

      // Handle working hours
      if (widget.initialData['workingHours'] != null) {
        final hours = widget.initialData['workingHours'].split(' - ');
        if (hours.length == 2) {
          _openingTime = _parseTime(hours[0]);
          _closingTime = _parseTime(hours[1]);
        }
      }
    }
  }

  // Helper function to parse time from string
  TimeOfDay _parseTime(String time) {
    final parts = time.split(' ');
    final timeParts = parts[0].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1].toLowerCase() == 'pm';
    return TimeOfDay(hour: isPM ? hour + 12 : hour, minute: minute);
  }

  // Function to show time picker
  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpeningTime ? _openingTime : _closingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
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
                    // Back button
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
                    // Salon Creation Title
                    const Text(
                      'Create Salon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add a new salon to the system',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Salon Logo Upload
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            _pickedImage != null
                                ? kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                      future: _pickedImage!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: 40,
                                          );
                                        } else if (snapshot.hasData) {
                                          return Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return Icon(
                                            Icons
                                                .add_a_photo, // Corrected: Use `Icons`
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            size: 40, // Added size parameter
                                          );
                                        }
                                      },
                                    )
                                    : Image.file(
                                      File(_pickedImage!.path),
                                    ) // For mobile
                                : Icon(
                                  Icons.add_a_photo, // Corrected: Use `Icons`
                                  color: Colors.white.withOpacity(0.5),
                                  size: 40, // Added size parameter
                                ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Salon Name Field
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
                            'Salon Name',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _salonNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter salon name',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Address Field
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
                            'Address',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _addressController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter salon address',
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
                            'Phone Number',
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
                              hintText: 'Enter phone number',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Workers Field
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
                            'Workers',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _workersController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter workers (comma separated)',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Vlasnik Field
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
                            'Vlasnik',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _vlasnikController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter vlasnik',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Working Days Field
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
                            'Working Days',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Wrap(
                            children:
                                _daysOfWeek.map((day) {
                                  return FilterChip(
                                    label: Text(day),
                                    selected: _selectedWorkingDays.contains(
                                      day,
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedWorkingDays.add(day);
                                        } else {
                                          _selectedWorkingDays.remove(day);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Working Hours Field
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
                            'Working Hours',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, true),
                                  child: Text(
                                    'Opening: ${_openingTime.format(context)}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectTime(context, false),
                                  child: Text(
                                    'Closing: ${_closingTime.format(context)}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Create Salon Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          print('Create Salon button clicked'); // Debug log

                          try {
                            // Get values from input fields
                            String salonName = _salonNameController.text.trim();
                            String address = _addressController.text.trim();
                            String phoneNumber =
                                _phoneNumberController.text.trim();
                            List<String> workers =
                                _workersController.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                            String vlasnik = _vlasnikController.text.trim();

                            print('Salon Name: $salonName'); // Debug log
                            print('Address: $address'); // Debug log
                            print('Phone Number: $phoneNumber'); // Debug log
                            print('Workers: $workers'); // Debug log
                            print('Vlasnik: $vlasnik'); // Debug log

                            // Validate required fields
                            if (salonName.isEmpty ||
                                address.isEmpty ||
                                phoneNumber.isEmpty ||
                                vlasnik.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all required fields.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Format working hours
                            String workingHours =
                                '${_openingTime.format(context)} - ${_closingTime.format(context)}';

                            // Upload image and get URL
                            String? logoUrl;
                            if (_pickedImage != null) {
                              print('Uploading image...'); // Debug log
                              logoUrl = await _uploadImage();
                              print(
                                'Image uploaded. URL: $logoUrl',
                              ); // Debug log
                            }

                            // Prepare the salon data
                            Map<String, dynamic> salonData = {
                              'naziv': salonName,
                              'adresa': address,
                              'brojTelefona': phoneNumber,
                              'radnici': workers, // Save workers as a list
                              'vlasnik': vlasnik,
                              'workingDays': _selectedWorkingDays,
                              'workingHours': workingHours,
                              'vlasnikId': null,
                              'kreiran': DateTime.now(),
                              'logoUrl': logoUrl, // Add logo URL
                            };

                            print('Saving salon data: $salonData'); // Debug log

                            // Save or update the salon in Firestore
                            if (widget.salonId.isEmpty) {
                              // Create a new salon
                              await FirebaseFirestore.instance
                                  .collection('saloni')
                                  .add(salonData);
                            } else {
                              // Update an existing salon
                              await FirebaseFirestore.instance
                                  .collection('saloni')
                                  .doc(widget.salonId)
                                  .update(salonData);
                            }

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Salon saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Clear input fields
                            _salonNameController.clear();
                            _addressController.clear();
                            _phoneNumberController.clear();
                            _workersController.clear();
                            _vlasnikController.clear();
                            setState(() {
                              _selectedWorkingDays = [];
                              _openingTime = TimeOfDay(hour: 9, minute: 0);
                              _closingTime = TimeOfDay(hour: 18, minute: 0);
                              _pickedImage = null;
                            });
                          } catch (e) {
                            // Show error message if something goes wrong
                            print('Error: $e'); // Debug log
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create Salon',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // View Salon List Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const SalonListAdminScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'View Salon List',
                          style: TextStyle(fontSize: 16),
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
