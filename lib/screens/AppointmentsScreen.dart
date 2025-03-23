import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frizerski_salon/screens/HaircutSettingsScreen.dart';
import 'package:frizerski_salon/screens/login_screen.dart'; // Dodaj import za LoginScreen

class AppointmentsScreen extends StatelessWidget {
  final String idSalona;
  final bool isOwner; // Provjera da li je korisnik vlasnik

  const AppointmentsScreen({
    Key? key,
    required this.idSalona,
    required this.isOwner,
  }) : super(key: key);

  void _deleteAppointment(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('termini').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Termin je obrisan!')),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HaircutSettingsScreen(salonId: idSalona),
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
                      'Zakazani termini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    // Prikazujemo dugmad ako je vlasnik
                    if (isOwner) ...[
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
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('termini')
                      .where('salonId', isEqualTo: idSalona)
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
                            subtitle: Text(
                              '${appointment['usluga']} - ${appointment['datum']} u ${appointment['vrijeme']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAppointment(
                                appointment.id,
                                context,
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
