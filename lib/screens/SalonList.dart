import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SalonCreationScreen.dart'; // Import the SalonCreationScreen for editing

class SalonListScreen extends StatelessWidget {
  const SalonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Frizerski saloni"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const SalonCreationScreen(
                        salonId: '',
                        initialData: {},
                      ),
                ),
              );
            },
          ),
        ],
      ),
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
                  title: Text(
                    naziv,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adresa),
                      Text(
                        " $brojTelefona",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Navigate to the SalonCreationScreen for editing
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SalonCreationScreen(
                                    salonId: idSalona,
                                    initialData: salon,
                                  ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Delete the salon
                          await FirebaseFirestore.instance
                              .collection('saloni')
                              .doc(idSalona)
                              .delete();
                        },
                      ),
                    ],
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
