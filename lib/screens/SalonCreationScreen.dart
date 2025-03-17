import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                          // Get values from input fields
                          String salonName = _salonNameController.text;
                          String address = _addressController.text;
                          String phoneNumber = _phoneNumberController.text;
                          List<String> workers =
                              _workersController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList();
                          String vlasnik = _vlasnikController.text;

                          // Format working hours
                          String workingHours =
                              '${_openingTime.format(context)} - ${_closingTime.format(context)}';

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
                          };

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
                              content: Text('Salon saved successfully'),
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
                          });
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
