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
  List<String> _favoritedSalons = []; // Track favorited salons
  int _selectedTabIndex = 0; // 0: Following, 1: Popular, 2: Recent

  // Function to toggle favorite and update Firestore
  Future<void> _toggleFavorite(String salonId) async {
    final salonRef = FirebaseFirestore.instance
        .collection('saloni')
        .doc(salonId);

    if (_favoritedSalons.contains(salonId)) {
      // Unfavorite: Decrement the favorite count
      await salonRef.update({'favorites': FieldValue.increment(-1)});
      setState(() {
        _favoritedSalons.remove(salonId);
      });
    } else {
      // Favorite: Increment the favorite count
      await salonRef.update({'favorites': FieldValue.increment(1)});
      setState(() {
        _favoritedSalons.add(salonId);
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

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
                    _onTabSelected(0);
                  },
                  child: Text(
                    'Following',
                    style: TextStyle(
                      color:
                          _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _onTabSelected(1);
                  },
                  child: Text(
                    'Popular',
                    style: TextStyle(
                      color:
                          _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _onTabSelected(2);
                  },
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      color:
                          _selectedTabIndex == 2
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
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

                // Filter salons based on search query and selected tab
                var filteredSalons =
                    salons.where((salon) {
                      var salonData = salon.data() as Map<String, dynamic>;
                      String naziv = salonData['naziv'] ?? '';

                      if (_searchQuery.isNotEmpty &&
                          !naziv.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )) {
                        return false;
                      }

                      if (_selectedTabIndex == 2 &&
                          !_favoritedSalons.contains(salon.id)) {
                        return false;
                      }

                      return true;
                    }).toList();

                // Sort salons by favorites (for Popular tab)
                if (_selectedTabIndex == 1) {
                  filteredSalons.sort((a, b) {
                    int aFavorites =
                        (a.data() as Map<String, dynamic>)['favorites'] ?? 0;
                    int bFavorites =
                        (b.data() as Map<String, dynamic>)['favorites'] ?? 0;
                    return bFavorites.compareTo(aFavorites); // Descending order
                  });
                }

                return ListView.builder(
                  itemCount: filteredSalons.length,
                  itemBuilder: (context, index) {
                    var salonDoc = filteredSalons[index];
                    var salon = salonDoc.data() as Map<String, dynamic>;
                    String idSalona = salonDoc.id;
                    String naziv = salon['naziv'] ?? 'Nepoznat salon';
                    String adresa = salon['adresa'] ?? 'Bez adrese';
                    String brojTelefona = salon['brojTelefona'] ?? 'Nema broja';
                    String? logoUrl = salon['logoUrl']; // Get logo URL
                    int favorites =
                        salon['favorites'] ?? 0; // Get favorite count

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
                              // Salon Logo
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF26A69A,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child:
                                    logoUrl != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: Image.network(
                                            logoUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : const Icon(
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'Favorites: $favorites', // Display favorite count
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Heart Icon for Favoriting
                              IconButton(
                                icon: Icon(
                                  _favoritedSalons.contains(idSalona)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      _favoritedSalons.contains(idSalona)
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                                onPressed: () {
                                  _toggleFavorite(idSalona);
                                },
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
