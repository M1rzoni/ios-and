import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frizerski_salon/screens/HaircutSettingsScreen.dart';
import 'package:frizerski_salon/screens/login_screen.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  final String idSalona;
  final bool isOwner;

  const AppointmentsScreen({
    Key? key,
    required this.idSalona,
    required this.isOwner,
  }) : super(key: key);

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime? _selectedDate;
  String? _selectedWorker;
  List<String> _workers = [];
  bool _isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
    // Postavi početni datum na danas
    _selectedDate = DateTime.now();
  }

  Future<void> _loadWorkers() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('saloni')
          .doc(widget.idSalona)
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = DateTime.now(); // Vrati na današnji datum
      _selectedWorker = null;
    });
  }

  void _deleteAppointment(String docId) async {
    await FirebaseFirestore.instance.collection('termini').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Termin je obrisan!')),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HaircutSettingsScreen(salonId: widget.idSalona),
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Metoda za parsiranje datuma iz formata "dd.MM.yyyy"
  DateTime? _parseAppointmentDate(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
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
          child: Column(
            children: [
              // AppBar sa logout dugmetom
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text(
                      'Zakazani termini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    if (widget.isOwner) ...[
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => _navigateToSettings(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ],
                ),
              ),
              // Filter sekcija
              Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Datum filter
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _selectDate(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.teal,
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Odaberite datum'
                                    : 'Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Radnik filter
                      DropdownButtonFormField<String>(
                        value: _selectedWorker,
                        decoration: InputDecoration(
                          labelText: 'Frizerski radnik',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Svi radnici'),
                          ),
                          ..._workers.map((worker) {
                            return DropdownMenuItem(
                              value: worker,
                              child: Text(worker),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedWorker = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      // Clear filter button
                      ElevatedButton(
                        onPressed: _selectedWorker == null ? null : _clearFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Očisti filtere'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('termini')
                      .where('salonId', isEqualTo: widget.idSalona)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Došlo je do greške.'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nema zakazanih termina.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    var appointments = snapshot.data!.docs;

                    // Filtriranje po datumu i radniku
                    appointments = appointments.where((appointment) {
                      // Parsiranje datuma iz dokumenta
                      final appointmentDate = _parseAppointmentDate(appointment['datum']);
                      if (appointmentDate == null) return false;

                      // Provjera datuma
                      final matchesDate = _selectedDate == null ||
                          (appointmentDate.year == _selectedDate!.year &&
                              appointmentDate.month == _selectedDate!.month &&
                              appointmentDate.day == _selectedDate!.day);

                      // Provjera radnika
                      final matchesWorker = _selectedWorker == null ||
                          appointment['worker'] == _selectedWorker;

                      return matchesDate && matchesWorker;
                    }).toList();

                    if (appointments.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nema termina za odabrane filtere.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        var appointment = appointments[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              appointment['ime'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${appointment['usluga']} - ${appointment['datum']} u ${appointment['vrijeme']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (appointment['worker'] != null)
                                  Text(
                                    'Frizerski radnik: ${appointment['worker']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAppointment(appointment.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}