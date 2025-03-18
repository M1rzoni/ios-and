import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
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
  List<Map<String, dynamic>> _services = [];
  List<String> _workers = [];
  bool _isLoading = true;
  String? _selectedWorker;
  late List<String> _workingDays;
  late String _workingHours;

  @override
  void initState() {
    super.initState();
    _fetchSalonDetails();
    _fetchServices();
    _fetchWorkers();
  }

  void _fetchSalonDetails() async {
    try {
      DocumentSnapshot salonSnapshot = await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.idSalona)
          .get();

      if (salonSnapshot.exists) {
        setState(() {
          _workingDays = List<String>.from(salonSnapshot['workingDays'] ?? []);
          _workingHours = salonSnapshot['workingHours'] ?? '10:00 AM - 6:00 PM';
        });
      }
    } catch (e) {
      print('Error fetching salon details: $e');
    }
  }

  void _fetchServices() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.idSalona)
          .collection('haircuts')
          .get();

      Set<String> uniqueTypes = {};
      List<Map<String, dynamic>> uniqueServices = [];

      for (var doc in querySnapshot.docs) {
        String type = doc['type'];
        if (!uniqueTypes.contains(type)) {
          uniqueTypes.add(type);
          uniqueServices.add({'type': type, 'price': doc['price']});
        }
      }

      setState(() {
        _services = uniqueServices;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fetchWorkers() async {
    try {
      DocumentSnapshot salonSnapshot = await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.idSalona)
          .get();

      if (salonSnapshot.exists) {
        List<dynamic> workers = salonSnapshot['radnici'] ?? [];
        setState(() {
          _workers = workers.cast<String>();
        });
      }
    } catch (e) {
      print('Error fetching workers: $e');
    }
  }

  void _navigateToAppointments(BuildContext context, String idSalona) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentsScreen(idSalona: idSalona),
      ),
    );
  }

  void _saveBooking() async {
    if (_nameController.text.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedWorker == null) {
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

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('termini')
        .where('salonId', isEqualTo: widget.idSalona)
        .where('datum', isEqualTo: formattedDate)
        .where('vrijeme', isEqualTo: formattedTime)
        .where('worker', isEqualTo: _selectedWorker)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Termin je već zauzet!'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('termini').add({
      'ime': _nameController.text,
      'usluga': _selectedService,
      'cijena': _selectedPrice,
      'datum': formattedDate,
      'vrijeme': formattedTime,
      'timestamp': FieldValue.serverTimestamp(),
      'salonId': widget.idSalona,
      'worker': _selectedWorker,
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
      _selectedWorker = null;
    });
  }

  void _pickDateTime() {
    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 30)),
      onChanged: (date) {},
      onConfirm: (date) {
        String selectedDay = DateFormat('EEEE').format(date);
        if (!_workingDays.contains(selectedDay)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salon ne radi na odabrani dan!'),
              backgroundColor: Color(0xFF26A69A),
            ),
          );
          return;
        }

        setState(() {
          _selectedDate = date;
        });
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

  void _showTimePicker() async {
    List<String> hours = _workingHours.split(' - ');
    TimeOfDay startTime = _parseTime(hours[0]);
    TimeOfDay endTime = _parseTime(hours[1]);

    List<String> timeSlots = [];
    TimeOfDay currentTime = startTime;

    while (currentTime.hour < endTime.hour ||
        (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute)) {
      timeSlots.add(_formatTime(currentTime));
      currentTime = _addMinutes(currentTime, 30);
    }

    List<String> bookedSlots = await _fetchBookedSlots();

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
                    bool isBooked = bookedSlots.contains(timeSlots[index]);
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked ? Colors.grey : Colors.grey.shade100,
                        foregroundColor: isBooked ? Colors.white : const Color(0xFF26A69A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isBooked
                          ? null
                          : () {
                        List<String> parts = timeSlots[index].split(':');
                        int hour = int.parse(parts[0]);
                        int minute = int.parse(parts[1].split(' ')[0]);
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

  Future<List<String>> _fetchBookedSlots() async {
    if (_selectedDate == null || _selectedWorker == null) return [];

    String formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDate!);

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('termini')
        .where('salonId', isEqualTo: widget.idSalona)
        .where('datum', isEqualTo: formattedDate)
        .where('worker', isEqualTo: _selectedWorker)
        .get();

    List<String> bookedSlots = [];
    for (var doc in querySnapshot.docs) {
      bookedSlots.add(doc['vrijeme']);
    }

    return bookedSlots;
  }

  TimeOfDay _parseTime(String time) {
    final format = DateFormat('h:mm a');
    DateTime dateTime = format.parse(time);
    return TimeOfDay.fromDateTime(dateTime);
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat('h:mm a');
    return format.format(dt);
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zakazivanje termina'),
        backgroundColor: const Color(0xFF26A69A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF26A69A),
              Color(0xFF80CBC4),
            ],
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
                        const SizedBox(height: 10),
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
                                  : _services.isEmpty
                                  ? const Text('Nema dostupnih usluga')
                                  : DropdownButtonFormField(
                                value: _selectedService,
                                items: _services.map((service) {
                                  return DropdownMenuItem(
                                    value: service['type'],
                                    child: Text(service['type']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedService = value as String?;
                                    var selectedService = _services.firstWhere(
                                          (service) => service['type'] == value,
                                      orElse: () => {'type': '', 'price': 0.0},
                                    );
                                    _selectedPrice = double.parse(selectedService['price'].toString());
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
                        const SizedBox(height: 20),
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
                                'Odaberite radnika',
                                style: TextStyle(
                                  color: Color(0xFF26A69A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              _workers.isEmpty
                                  ? const Text('Nema dostupnih radnika')
                                  : DropdownButtonFormField(
                                value: _selectedWorker,
                                items: _workers.map((worker) {
                                  return DropdownMenuItem(
                                    value: worker,
                                    child: Text(worker),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedWorker = value as String?;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Odaberite radnika',
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
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            onPressed: _pickDateTime,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_selectedDate != null && _selectedTime != null)
                                  ? const Color(0xFF26A69A)
                                  : Colors.grey.shade100,
                              foregroundColor: (_selectedDate != null && _selectedTime != null)
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
                                  (_selectedDate == null || _selectedTime == null)
                                      ? 'Odaberite datum i vrijeme'
                                      : '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} - ${_selectedTime!.format(context)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => _navigateToAppointments(context, widget.idSalona ?? ""),
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