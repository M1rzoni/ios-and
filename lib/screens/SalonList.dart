import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class SalonListScreen extends StatefulWidget {
  const SalonListScreen({super.key});

  @override
  _SalonListScreenState createState() => _SalonListScreenState();
}

class _SalonListScreenState extends State<SalonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pretraži salone...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF26A69A),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Navbar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF26A69A).withOpacity(0.9),
                  const Color(0xFF80CBC4).withOpacity(0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle "Following" tab
                  },
                  child: const Text(
                    'Following',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle "Popular" tab
                  },
                  child: const Text(
                    'Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle "Recent" tab
                  },
                  child: const Text(
                    'Recent',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Salon List
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('saloni').snapshots(),
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

                // Filter salons based on search query
                var filteredSalons =
                    salons.where((salon) {
                      var salonData = salon.data() as Map<String, dynamic>;
                      String naziv = salonData['naziv'] ?? '';
                      return naziv.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                return ListView.builder(
                  itemCount: filteredSalons.length,
                  itemBuilder: (context, index) {
                    var salonDoc = filteredSalons[index];
                    var salon = salonDoc.data() as Map<String, dynamic>;
                    String idSalona = salonDoc.id;
                    String naziv = salon['naziv'] ?? 'Nepoznat salon';
                    String adresa = salon['adresa'] ?? 'Bez adrese';
                    String brojTelefona = salon['brojTelefona'] ?? 'Nema broja';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      BookingScreen(idSalona: idSalona),
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
                                  color: const Color(
                                    0xFF26A69A,
                                  ).withOpacity(0.1),
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
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF26A69A),
                                size: 20,
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
          ),
        ],
      ),
    );
  }
}
