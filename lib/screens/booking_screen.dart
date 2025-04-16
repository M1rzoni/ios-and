import 'package:firebase_auth/firebase_auth.dart';
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
  List<String> _selectedServices = [];
  double _totalPrice = 0.0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Map<String, dynamic>> _services = [];
  List<String> _workers = [];
  bool _isLoading = true;
  String? _selectedWorker;
  late List<String> _workingDays;
  late String _workingHours;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchSalonDetails();
    _fetchServices();
    _fetchWorkers();
    _fetchAlerts();
  }

  void _fetchAlerts() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('saloni')
              .doc(widget.idSalona)
              .collection('alerts')
              .where('expirationDate', isGreaterThanOrEqualTo: DateTime.now())
              .get();

      setState(() {
        _alerts =
            querySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
    } catch (e) {
      print('Error fetching alerts: $e');
    }
  }

  void _fetchSalonDetails() async {
  try {
    DocumentSnapshot salonSnapshot = await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.idSalona)
        .get();

    if (salonSnapshot.exists) {
      // Konvertujemo radno vrijeme u 24-satni format
      String workingHours12h = salonSnapshot['workingHours'] ?? '10:00 AM - 6:00 PM';
      String workingHours24h = _convertTo24HourFormat(workingHours12h);

      setState(() {
        _workingDays = List<String>.from(salonSnapshot['workingDays'] ?? []);
        _workingHours = workingHours24h; // Spremamo u 24-satnom formatu
      });
    }
  } catch (e) {
    print('Error fetching salon details: $e');
    }
  }

  String _convertTo24HourFormat(String time12h) {
    try {
      // Očistimo string od nepotrebnih znakova
      String cleanedTime = time12h
          .replaceAll(' ', ' ')
          .trim();

      List<String> parts = cleanedTime.split(' - ');
      if (parts.length != 2) return time12h;

      String startTime12h = parts[0];
      String endTime12h = parts[1];

      // Funkcija za konverziju pojedinačnog vremena
      String convertSingleTime(String time12h) {
        final format12h = DateFormat('h:mm a');
        final format24h = DateFormat('HH:mm');
        DateTime dateTime = format12h.parse(time12h.trim());
        return format24h.format(dateTime);
      }

      return '${convertSingleTime(startTime12h)} - ${convertSingleTime(endTime12h)}';
    } catch (e) {
      print('Error converting time format: $e');
      return time12h;
    }
  }

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
            querySnapshot.docs.map((doc) {
              // Parse price as double, removing any non-numeric characters if needed
              String priceString = doc['price'].toString().replaceAll(
                RegExp(r'[^0-9.]'),
                '',
              );
              double price = double.tryParse(priceString) ?? 0.0;

              return {
                'id': doc.id,
                'type': doc['type'],
                'price': price, // Store as double
              };
            }).toList();
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
      DocumentSnapshot salonSnapshot =
          await FirebaseFirestore.instance
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

  void _saveBooking() async {
    // Provjeri da li je termin u prošlosti
    if (_selectedDate != null && _selectedTime != null) {
      final now = DateTime.now();
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (appointmentDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ne možete rezervisati termin u prošlosti!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Dohvati trenutnog korisnika
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Morate biti prijavljeni da biste rezervisali termin!'),
          backgroundColor: Color(0xFF26A69A),
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        _selectedServices.isEmpty ||
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

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
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
      'usluge': _selectedServices,
      'cijena': _totalPrice,
      'datum': formattedDate,
      'vrijeme': formattedTime,
      'timestamp': FieldValue.serverTimestamp(),
      'salonId': widget.idSalona,
      'worker': _selectedWorker,
      'userId': user.uid, // Dodajemo user UUID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Termin uspješno zakazan!'),
        backgroundColor: Color(0xFF26A69A),
      ),
    );

    _nameController.clear();
    setState(() {
      _selectedServices = [];
      _totalPrice = 0.0;
      _selectedDate = null;
      _selectedTime = null;
      _selectedWorker = null;
    });
  }

  void _toggleServiceSelection(
    String serviceId,
    String serviceType,
    double price,
  ) {
    setState(() {
      if (_selectedServices.contains(serviceType)) {
        _selectedServices.remove(serviceType);
        _totalPrice -= price;
      } else {
        _selectedServices.add(serviceType);
        _totalPrice += price;
      }
    });
  }

  void _pickDateTime() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    picker.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(const Duration(days: 30)),
      onChanged: (date) {},
      onConfirm: (date) {
        // Provjeri da li je odabrani datum danas
        bool isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

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
        _showTimePicker(isToday: isToday, currentTime: currentTime);
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

  void _showTimePicker({bool isToday = false, TimeOfDay? currentTime}) async {
    List<String> hours = _workingHours.split(' - ');
    TimeOfDay startTime = _parseTime(hours[0]);
    TimeOfDay endTime = _parseTime(hours[1]);

    List<String> timeSlots = [];
    TimeOfDay currentSlot = startTime;

    while (currentSlot.hour < endTime.hour ||
        (currentSlot.hour == endTime.hour &&
            currentSlot.minute < endTime.minute)) {
      // Ako je danas i vrijeme je u prošlosti, preskoči
      if (!isToday || !_isTimeInPast(currentSlot, currentTime!)) {
        timeSlots.add(_formatTime(currentSlot));
      }
      currentSlot = _addMinutes(currentSlot, 30);
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
                child:
                    timeSlots.isEmpty
                        ? const Center(
                          child: Text('Nema dostupnih termina za odabrani dan'),
                        )
                        : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemCount: timeSlots.length,
                          itemBuilder: (context, index) {
                            bool isBooked = bookedSlots.contains(
                              timeSlots[index],
                            );
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isBooked
                                        ? Colors.grey
                                        : Colors.grey.shade100,
                                foregroundColor:
                                    isBooked
                                        ? Colors.white
                                        : const Color(0xFF26A69A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  isBooked
                                      ? null
                                      : () {
                                        List<String> parts = timeSlots[index]
                                            .split(':');
                                        int hour = int.parse(parts[0]);
                                        int minute = int.parse(
                                          parts[1].split(' ')[0],
                                        );
                                        setState(() {
                                          _selectedTime = TimeOfDay(
                                            hour: hour,
                                            minute: minute,
                                          );
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

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
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
    try {
      // Prvo očistimo string od nepotrebnih znakova
      String cleanedTime = time
          .replaceAll(' ', ' ') // Zamjena specijalnog razmaka sa običnim razmakom
          .trim(); // Uklanjanje praznina sa početka i kraja

      // Provjeravamo da li je u 12-satnom formatu (sadrži AM/PM)
      if (cleanedTime.toLowerCase().contains('am') || cleanedTime.toLowerCase().contains('pm')) {
        final format = DateFormat('h:mm a');
        DateTime dateTime = format.parse(cleanedTime);
        return TimeOfDay.fromDateTime(dateTime);
      } else {
        // Ako je u 24-satnom formatu
        // Uklanjamo sve ne-brojčane znakove osim dvotačke
        String numbersOnly = cleanedTime.replaceAll(RegExp(r'[^0-9:]'), '');
        List<String> parts = numbersOnly.split(':');
        
        if (parts.length != 2) {
          throw FormatException('Invalid time format: $time');
        }
        
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing time: $time, error: $e');
      // Vraćamo podrazumijevano vrijeme u slučaju greške
      return TimeOfDay(hour: 10, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute + minutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  // Pomoćna metoda za provjeru da li je vrijeme u prošlosti
  bool _isTimeInPast(TimeOfDay slotTime, TimeOfDay currentTime) {
    if (slotTime.hour < currentTime.hour) return true;
    if (slotTime.hour == currentTime.hour &&
        slotTime.minute <= currentTime.minute) {
      return true;
    }
    return false;
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
                        if (_alerts.isNotEmpty)
                          Column(
                            children:
                                _alerts.map((alert) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alert['text'],
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Objavljeno: ${DateFormat('dd.MM.yyyy').format((alert['timestamp'] as Timestamp).toDate())}',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
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
                                'Odaberite usluge',
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
                                  : Column(
                                    children:
                                        _services.map((service) {
                                          return CheckboxListTile(
                                            title: Text(service['type']),
                                            subtitle: Text(
                                              '${service['price'].toStringAsFixed(2)} KM',
                                            ),
                                            value: _selectedServices.contains(
                                              service['type'],
                                            ),
                                            onChanged: (bool? selected) {
                                              if (selected != null) {
                                                _toggleServiceSelection(
                                                  service['id'],
                                                  service['type'],
                                                  double.parse(
                                                    service['price'].toString(),
                                                  ),
                                                );
                                              }
                                            },
                                            activeColor: const Color(
                                              0xFF26A69A,
                                            ),
                                          );
                                        }).toList(),
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
                                    items:
                                        _workers.map((worker) {
                                          return DropdownMenuItem(
                                            value: worker,
                                            child: Text(worker),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedWorker = value;
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
                        if (_selectedServices.isNotEmpty)
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Odabrane usluge:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF26A69A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children:
                                      _selectedServices.map((service) {
                                        var serviceData = _services.firstWhere(
                                          (s) => s['type'] == service,
                                          orElse:
                                              () => {'type': '', 'price': 0.0},
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(service),
                                              Text(
                                                '${serviceData['price'].toStringAsFixed(2)} KM',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Ukupno:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF26A69A),
                                      ),
                                    ),
                                    Text(
                                      '${_totalPrice.toStringAsFixed(2)} KM',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF26A69A),
                                      ),
                                    ),
                                  ],
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
                                  (_selectedDate == null || _selectedTime == null)
                                      ? 'Odaberite datum i vrijeme'
                                      : '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} - ${_formatTime(_selectedTime!)}', // Koristite _formatTime umjesto _selectedTime!.format(context)
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
