import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  void _deleteAppointment(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('termini').doc(docId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Termin je obrisan!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zakazani termini')),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('termini')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(child: Text('Nema zakazanih termina.'));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(appointment['ime']),
                  subtitle: Text(
                    '${appointment['usluga']} - ${appointment['datum']} u ${appointment['vrijeme']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed:
                        () => _deleteAppointment(appointment.id, context),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
