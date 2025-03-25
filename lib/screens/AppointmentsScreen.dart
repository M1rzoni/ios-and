import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frizerski_salon/screens/HaircutSettingsScreen.dart';
import 'package:frizerski_salon/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      _selectedDate = DateTime.now();
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

  Future<Map<String, dynamic>?> _fetchUserDetails(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  Future<String?> _getProfileImageUrl(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$userId');
      return await ref.getDownloadURL();
    } catch (e) {
      print('No profile image found: $e');
      return null;
    }
  }

  void _showAppointmentDetails(BuildContext context, DocumentSnapshot appointment) async {
    final userDetails = await _fetchUserDetails(appointment['userId']);
    final imageUrl = userDetails?['profileImageUrl'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Detalji termina',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // User Info Section with image on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Korisnik:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildDetailRow('Ime i prezime:', userDetails?['fullName'] ?? 'Nepoznato'),
                        _buildDetailRow('Email:', userDetails?['email'] ?? 'Nepoznato'),
                        _buildDetailRow('Broj telefona:', userDetails?['phoneNumber'] ?? 'Nepoznato'),
                      ],
                    ),
                  ),

                  // Right side - Profile image
                  if (imageUrl != null)
                    Container(
                      margin: EdgeInsets.only(left: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Icon(Icons.person),
                        ),
                      ),
                    ),
                ],
              ),

              Divider(thickness: 2, height: 30),

              // Appointment Details Section
              Text(
                'Detalji rezervacije:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              _buildDetailRow('Ime na rezervaciji:', appointment['ime']),
              _buildDetailRow('Datum:', appointment['datum']),
              _buildDetailRow('Vrijeme:', appointment['vrijeme']),
              _buildDetailRow('Frizerski radnik:', appointment['worker'] ?? 'Nepoznato'),
              _buildDetailRow('Cijena:', '${appointment['cijena'] ?? 'Nepoznato'} KM'),

              // Services
              SizedBox(height: 10),
              Text(
                'Usluge:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(appointment['usluge'] as List<dynamic>? ?? []).map((service) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4),
                    child: Text('- $service'),
                  )
              ).toList(),

              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Zatvori'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _deleteAppointment(appointment.id);
                      Navigator.pop(context);
                    },
                    child: Text('Obriši termin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
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
              Color(0xFF26A69A),
              Color(0xFF80CBC4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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

                    appointments = appointments.where((appointment) {
                      final appointmentDate = _parseAppointmentDate(appointment['datum']);
                      if (appointmentDate == null) return false;

                      final matchesDate = _selectedDate == null ||
                          (appointmentDate.year == _selectedDate!.year &&
                              appointmentDate.month == _selectedDate!.month &&
                              appointmentDate.day == _selectedDate!.day);

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
                          child: InkWell(
                            onTap: () => _showAppointmentDetails(context, appointment),
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
                                    '${appointment['datum']} u ${appointment['vrijeme']}',
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