import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'AppointmentsScreen.dart';

class BookingScreen extends StatefulWidget {
  final String? idSalona;

  const BookingScreen({super.key, this.idSalona});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedService;
  double? _selectedPrice;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _services = []; // List to store fetched services
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchServices(); // Fetch services when the screen loads
  }

  // Fetch services from Firestore
  void _fetchServices() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('saloni')
              .doc(widget.idSalona)
              .collection('haircuts')
              .get();

      setState(() {
        _services =
            querySnapshot.docs
                .map((doc) => {'type': doc['type'], 'price': doc['price']})
                .toList();
        _isLoading = false; // Stop loading
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() {
        _isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  void _pickDateTime() {
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 30)),
      onChanged: (date) {},
      onConfirm: (date) {
        // Check if weekend (6 = Saturday, 7 = Sunday)
        if (date.weekday == 6 || date.weekday == 7) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Možete zakazati samo od ponedjeljka do petka!'),
              backgroundColor: Color(0xFF26A69A),
            ),
          );
          return;
        }
        setState(() {
          _selectedDate = date;
        });
        // After selecting date, show time picker
        _showTimePicker();
      },
      currentTime: DateTime.now(),
      locale: picker.LocaleType.hr,
      theme: picker.DatePickerTheme(
        headerColor: const Color(0xFF26A69A),
        backgroundColor: Colors.white,
        itemStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        doneStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        cancelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  void _showTimePicker() {
    // Business hours from 9:00 to 17:00
    List<String> timeSlots = [];
    // Generate time slots for each hour and half hour
    for (int hour = 9; hour < 17; hour++) {
      // Add the on-the-hour slot (e.g., 9:00)
      timeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      // Add the half-hour slot (e.g., 9:30) if not the last hour
      if (hour < 16) {
        timeSlots.add('${hour.toString().padLeft(2, '0')}:30');
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Odaberite vrijeme",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26A69A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF26A69A)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: const Color(0xFF26A69A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Parse the time string
                        List<String> parts = timeSlots[index].split(':');
                        int hour = int.parse(parts[0]);
                        int minute = int.parse(parts[1]);
                        // Set the selected time and close the modal
                        setState(() {
                          _selectedTime = TimeOfDay(hour: hour, minute: minute);
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        timeSlots[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveBooking() async {
    if (_nameController.text.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo popunite sva polja!'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
      return;
    }

    String formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDate!);
    String formattedTime = _selectedTime!.format(context);

    await FirebaseFirestore.instance.collection('termini').add({
      'ime': _nameController.text,
      'usluga': _selectedService,
      'cijena': _selectedPrice,
      'datum': formattedDate,
      'vrijeme': formattedTime,
      'timestamp': FieldValue.serverTimestamp(),
      'salonId': widget.idSalona,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termin uspješno zakazan!'),
        backgroundColor: Color(0xFF26A69A),
      ),
    );

    _nameController.clear();
    setState(() {
      _selectedService = null;
      _selectedPrice = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _navigateToAppointments(BuildContext context, String idSalona) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentsScreen(idSalona: idSalona),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Zakazivanje termina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                        const SizedBox(height: 10),
                        // Name field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vaše ime',
                                style: TextStyle(
                                  color: Color(0xFF26A69A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Unesite vaše ime',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Service dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Odaberite uslugu',
                                style: TextStyle(
                                  color: Color(0xFF26A69A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : DropdownButtonFormField(
                                    value: _selectedService,
                                    items:
                                        _services.map((service) {
                                          return DropdownMenuItem(
                                            value: service['type'],
                                            child: Text(service['type']),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedService = value as String?;
                                        _selectedPrice = double.parse(
                                          _services.firstWhere(
                                            (service) =>
                                                service['type'] == value,
                                          )['price'],
                                        );
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Odaberite uslugu',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF26A69A),
                                    ),
                                    dropdownColor: Colors.white,
                                  ),
                            ],
                          ),
                        ),
                        // Price display
                        if (_selectedPrice != null)
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26A69A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  color: Color(0xFF26A69A),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Cijena: ${_selectedPrice!.toStringAsFixed(2)} KM',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Date and time selector - combined into one button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            onPressed: _pickDateTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_selectedDate != null &&
                                          _selectedTime != null)
                                      ? const Color(0xFF26A69A)
                                      : Colors.grey.shade100,
                              foregroundColor:
                                  (_selectedDate != null &&
                                          _selectedTime != null)
                                      ? Colors.white
                                      : Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  (_selectedDate == null ||
                                          _selectedTime == null)
                                      ? 'Odaberite datum i vrijeme'
                                      : '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} - ${_selectedTime!.format(context)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Confirm button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A60),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Potvrdi termin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // View appointments button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed:
                                () => _navigateToAppointments(
                                  context,
                                  widget.idSalona ?? "",
                                ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF26A69A),
                              side: const BorderSide(color: Color(0xFF26A69A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month),
                                SizedBox(width: 8),
                                Text(
                                  'Prikaži rezervisane termine',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
