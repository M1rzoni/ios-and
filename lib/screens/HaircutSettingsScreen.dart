import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Za rad s datumima

class HaircutSettingsScreen extends StatefulWidget {
  final String salonId;

  const HaircutSettingsScreen({super.key, required this.salonId});

  @override
  _HaircutSettingsScreenState createState() => _HaircutSettingsScreenState();
}

class _HaircutSettingsScreenState extends State<HaircutSettingsScreen> {
  final TextEditingController _haircutTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _alertController = TextEditingController();
  final TextEditingController _workerController = TextEditingController();
  DateTime? _expirationDate;

  // Working hours state
  List<String> _workingDays = [];
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;
  bool _isLoadingWorkingHours = true;

  // Workers state
  List<String> _workers = [];
  bool _isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
    _loadWorkers();
  }

  Future<void> _loadWorkingHours() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('saloni')
              .doc(widget.salonId)
              .get();

      if (doc.exists) {
        setState(() {
          _workingDays = List<String>.from(doc['workingDays'] ?? []);
          if (doc['workingHours'] != null) {
            final hours = doc['workingHours'].toString().split(' - ');
            if (hours.length == 2) {
              _openingTime = _parseTime(hours[0]);
              _closingTime = _parseTime(hours[1]);
            }
          }
          _isLoadingWorkingHours = false;
        });
      }
    } catch (e) {
      print('Error loading working hours: $e');
      setState(() {
        _isLoadingWorkingHours = false;
      });
    }
  }

  Future<void> _loadWorkers() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('saloni')
              .doc(widget.salonId)
              .get();

      if (doc.exists) {
        setState(() {
          _workers = List<String>.from(doc['radnici'] ?? []);
          _isLoadingWorkers = false;
        });
      }
    } catch (e) {
      print('Error loading workers: $e');
      setState(() {
        _isLoadingWorkers = false;
      });
    }
  }

  Future<void> _addWorker() async {
    final workerName = _workerController.text.trim();
    if (workerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite ime radnika.')),
      );
      return;
    }

    try {
      // Check if worker already exists
      if (_workers.contains(workerName)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Radnik već postoji.')));
        return;
      }

      // Add worker to Firestore
      await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.salonId)
          .update({
            'radnici': FieldValue.arrayUnion([workerName]),
          });

      // Update local state
      setState(() {
        _workers.add(workerName);
        _workerController.clear();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Radnik je dodan!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri dodavanju radnika: $e')),
      );
    }
  }

  Future<void> _removeWorker(String workerName) async {
    try {
      // Remove worker from Firestore
      await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.salonId)
          .update({
            'radnici': FieldValue.arrayRemove([workerName]),
          });

      // Update local state
      setState(() {
        _workers.remove(workerName);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Radnik je uklonjen!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri uklanjanju radnika: $e')),
      );
    }
  }

  Widget _buildWorkersSection() {
    if (_isLoadingWorkers) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Radnici u salonu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Add worker input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _workerController,
                    decoration: const InputDecoration(
                      labelText: 'Ime radnika',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.teal),
                  onPressed: _addWorker,
                  tooltip: 'Dodaj radnika',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workers list
            if (_workers.isEmpty)
              const Center(child: Text('Nema dodanih radnika.')),
            if (_workers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lista radnika:'),
                  const SizedBox(height: 8),
                  ..._workers
                      .map(
                        (worker) => ListTile(
                          title: Text(worker),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeWorker(worker),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final format = DateFormat.jm(); // Parses AM/PM format
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      print('Error parsing time: $e');
      return null;
    }
  }

  Future<void> _saveWorkingHours() async {
    if (_openingTime == null || _closingTime == null || _workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo odaberite dane i vrijeme rada.')),
      );
      return;
    }

    final openingTimeStr = _formatTime(_openingTime!);
    final closingTimeStr = _formatTime(_closingTime!);
    final workingHours = '$openingTimeStr - $closingTimeStr';

    try {
      await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.salonId)
          .update({'workingDays': _workingDays, 'workingHours': workingHours});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Radno vrijeme je spremljeno!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška pri spremanju: $e')));
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _selectTime(BuildContext context, bool isOpeningTime) async {
    final initialTime = isOpeningTime ? _openingTime : _closingTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay(hour: 9, minute: 0),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTime = selectedTime;
        } else {
          _closingTime = selectedTime;
        }
      });
    }
  }

  void _toggleWorkingDay(String day) {
    setState(() {
      if (_workingDays.contains(day)) {
        _workingDays.remove(day);
      } else {
        _workingDays.add(day);
      }
    });
  }

  Widget _buildWorkingHoursSection() {
    if (_isLoadingWorkingHours) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Radno vrijeme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Working days selection
            const Text('Radni dani:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday',
                  ].map((day) {
                    final isSelected = _workingDays.contains(day);
                    return FilterChip(
                      label: Text(_translateDay(day)),
                      selected: isSelected,
                      onSelected: (selected) => _toggleWorkingDay(day),
                      selectedColor: Colors.teal.withOpacity(0.2),
                      checkmarkColor: Colors.teal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.teal : Colors.black,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Working hours selection
            const Text('Radno vrijeme:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                    ),
                    child: Text(
                      _openingTime != null
                          ? 'Otvaranje: ${_openingTime!.format(context)}'
                          : 'Odaberite vrijeme otvaranja',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _selectTime(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                    ),
                    child: Text(
                      _closingTime != null
                          ? 'Zatvaranje: ${_closingTime!.format(context)}'
                          : 'Odaberite vrijeme zatvaranja',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Save button
            Center(
              child: ElevatedButton(
                onPressed: _saveWorkingHours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Spremi radno vrijeme'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateDay(String englishDay) {
    switch (englishDay) {
      case 'Monday':
        return 'Ponedjeljak';
      case 'Tuesday':
        return 'Utorak';
      case 'Wednesday':
        return 'Srijeda';
      case 'Thursday':
        return 'Četvrtak';
      case 'Friday':
        return 'Petak';
      case 'Saturday':
        return 'Subota';
      case 'Sunday':
        return 'Nedjelja';
      default:
        return englishDay;
    }
  }

  void _addHaircutType() async {
    final String haircutType = _haircutTypeController.text.trim();
    final String price = _priceController.text.trim();

    if (haircutType.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite vrstu frizure i cijenu.')),
      );
      return;
    }

    // Add haircut type and price to Firestore
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .add({
          'type': haircutType,
          'price': price,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Clear input fields
    _haircutTypeController.clear();
    _priceController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frizura je dodana!')));
  }

  Stream<QuerySnapshot> _getHaircutsStream() {
    return FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .snapshots();
  }

  Stream<QuerySnapshot> _getAlertsStream() {
    return FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .snapshots();
  }

  void _editHaircut(String id, String type, String price) {
    _haircutTypeController.text = type;
    _priceController.text = price;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uredi frizuru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _haircutTypeController,
                decoration: const InputDecoration(labelText: 'Vrsta frizure'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Cijena'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('saloni')
                    .doc(widget.salonId)
                    .collection('haircuts')
                    .doc(id)
                    .update({
                      'type': _haircutTypeController.text.trim(),
                      'price': _priceController.text.trim(),
                    });
                Navigator.pop(context);
                _haircutTypeController.clear();
                _priceController.clear();
              },
              child: const Text('Spremi'),
            ),
          ],
        );
      },
    );
  }

  void _deleteHaircut(String id) async {
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .doc(id)
        .delete();
  }

  void _editAlert(String id, String text, DateTime expirationDate) {
    _alertController.text = text;
    _expirationDate = expirationDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uredi notifikaciju'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _alertController,
                decoration: const InputDecoration(
                  labelText: 'Tekst notifikacije',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _expirationDate == null
                      ? 'Odaberite datum isteka'
                      : 'Datum isteka: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('saloni')
                    .doc(widget.salonId)
                    .collection('alerts')
                    .doc(id)
                    .update({
                      'text': _alertController.text.trim(),
                      'expirationDate': _expirationDate,
                    });
                Navigator.pop(context);
                _alertController.clear();
                setState(() {
                  _expirationDate = null;
                });
              },
              child: const Text('Spremi'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAlert(String id) async {
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .doc(id)
        .delete();
  }

  void _addAlert() async {
    final String alertText = _alertController.text.trim();

    if (alertText.isEmpty || _expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo unesite tekst notifikacije i datum isteka.'),
        ),
      );
      return;
    }

    // Add alert to Firestore
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .add({
          'text': alertText,
          'expirationDate': _expirationDate,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Clear input fields
    _alertController.clear();
    setState(() {
      _expirationDate = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Notifikacija je dodana!')));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Widget _buildHaircutsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upravljanje frizurama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Input fields for haircut
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _haircutTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Vrsta frizure',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Cijena (KM)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.teal),
                  onPressed: _addHaircutType,
                  tooltip: 'Dodaj frizuru',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Haircuts list
            const Text('Dodane frizure:'),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _getHaircutsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nema dodanih frizura.'));
                }

                final haircuts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: haircuts.length,
                  itemBuilder: (context, index) {
                    final haircut = haircuts[index];
                    return ListTile(
                      title: Text(haircut['type']),
                      subtitle: Text('${haircut['price']} KM'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _editHaircut(
                                  haircut.id,
                                  haircut['type'],
                                  haircut['price'],
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHaircut(haircut.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upravljanje notifikacijama',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Input fields for alerts
            TextField(
              controller: _alertController,
              decoration: const InputDecoration(
                labelText: 'Tekst notifikacije',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                _expirationDate == null
                    ? 'Odaberite datum isteka'
                    : 'Datum isteka: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addAlert,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Dodaj notifikaciju'),
            ),
            const SizedBox(height: 16),

            // Alerts list
            const Text('Dodane notifikacije:'),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _getAlertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nema dodanih notifikacija.'),
                  );
                }

                final alerts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final expirationDate =
                        (alert['expirationDate'] as Timestamp).toDate();
                    return ListTile(
                      title: Text(alert['text']),
                      subtitle: Text(
                        'Istječe: ${DateFormat('dd/MM/yyyy').format(expirationDate)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => _editAlert(
                                  alert.id,
                                  alert['text'],
                                  expirationDate,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAlert(alert.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Postavke salona',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Working Hours Section
                      _buildWorkingHoursSection(),

                      // Workers Section
                      _buildWorkersSection(),

                      // Haircuts Section
                      _buildHaircutsSection(),

                      // Alerts Section
                      _buildAlertsSection(),
                    ],
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
