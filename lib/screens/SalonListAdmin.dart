import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SalonCreationScreen.dart'; // Import the SalonCreationScreen for editing

class SalonListAdminScreen extends StatelessWidget {
  const SalonListAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Frizerski saloni",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF26A69A), // Teal color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Nema dostupnih salona.",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            );
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Salon Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF26A69A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Color(0xFF26A69A),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Salon Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                naziv,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF26A69A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                adresa,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                brojTelefona,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit and Delete Buttons
                        Row(
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
                      ],
                    ),
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
