import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class SalonListScreen extends StatelessWidget {
  const SalonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Frizerski saloni")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('saloni').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nema dostupnih salona."));
          }

          var salons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: salons.length,
            itemBuilder: (context, index) {
              var salonDoc = salons[index];
              var salon = salonDoc.data() as Map<String, dynamic>;
              String idSalona = salonDoc.id;
              String naziv = salon['naziv'] ?? 'Nepoznat salon';
              String adresa = salon['adresa'] ?? 'Bez adrese';
              String brojTelefona = salon['brojTelefona'] ?? 'Nema broja';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.store, color: Colors.grey[700]),
                  ),
                  title: Text(naziv, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adresa),
                      Text(" $brojTelefona", style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingScreen(idSalona: idSalona),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}