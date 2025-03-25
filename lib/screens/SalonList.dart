import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frizerski_salon/cities_list.dart';
import 'package:frizerski_salon/screens/login_screen.dart';
import 'package:frizerski_salon/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'booking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SalonListScreen extends StatefulWidget {
  const SalonListScreen({super.key});

  @override
  _SalonListScreenState createState() => _SalonListScreenState();
}

class _SalonListScreenState extends State<SalonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAppointmentsModalShowing = false;
  List<String> _favoritedSalons = []; // Lista ID-jeva lajkovanih salona
  int _selectedTabIndex = 0; // 0: Following, 1: Popular, 2: Recent
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadFavoritedSalons(); // Učitaj lajkovane salone prilikom učitavanja ekrana
  }

  // Funkcija za učitavanje lajkovanih salona iz Firestore-a
  Future<void> _loadFavoritedSalons() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Ako korisnik nije prijavljen, ne radi ništa

    final userId = user.uid;
    final favoritedSalons = await getFavoritedSalons(userId);
    setState(() {
      _favoritedSalons = favoritedSalons;
    });
  }

  // Funkcija za dohvaćanje lajkovanih salona iz korisničkog dokumenta
  Future<List<String>> getFavoritedSalons(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        List<dynamic> favorites = userDoc.data()?['favorites'] ?? [];
        return favorites.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching favorited salons: $e');
      return [];
    }
  }

  DateTime _parseAppointmentDate(String dateString) {
    try {
      // Parse "dd.MM.yyyy" format
      final parts = dateString.split('.');
      if (parts.length != 3) throw FormatException('Invalid date format');

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date "$dateString": $e');
      return DateTime.now(); // Fallback to current date if parsing fails
    }
  }

  // Funkcija za ažuriranje lajkovanih salona u korisničkom dokumentu
  Future<void> updateFavoritedSalons(
    String userId,
    List<String> favoritedSalons,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'favorites': favoritedSalons,
      });
    } catch (e) {
      print('Error updating favorited salons: $e');
    }
  }

  // Funkcija za lajkanje/odlajkanje salona
  Future<void> _toggleFavorite(String salonId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Ako korisnik nije prijavljen, ne radi ništa

    final userId = user.uid;

    if (_favoritedSalons.contains(salonId)) {
      // Odlajkaj: Ukloni salon iz liste lajkovanih
      setState(() {
        _favoritedSalons.remove(salonId);
      });
    } else {
      // Lajkaj: Dodaj salon u listu lajkovanih
      setState(() {
        _favoritedSalons.add(salonId);
      });
    }

    // Ažuriraj Firestore
    await updateFavoritedSalons(userId, _favoritedSalons);

    // Ažuriraj broj lajkova u kolekciji saloni
    final salonRef = FirebaseFirestore.instance
        .collection('saloni')
        .doc(salonId);
    if (_favoritedSalons.contains(salonId)) {
      await salonRef.update({'favorites': FieldValue.increment(1)});
    } else {
      await salonRef.update({'favorites': FieldValue.increment(-1)});
    }
  }

  Future<Icon> testImageDownload() async {
    try {
      final url = 'https://firebasestorage.googleapis.com/v0/b/binaryteam-31798.appspot.com/o/salon_logos%2F1742902410946.jpg?alt=media&token=8f7ca908-c9a3-4b81-9750-87007c787920';

      // 1. Provera HEAD zahtjeva
      final headResponse = await http.head(Uri.parse(url));
      print('HEAD Response - Status: ${headResponse.statusCode}');
      print('Headers: ${headResponse.headers}');

      // 2. Provera GET zahtjeva
      final getResponse = await http.get(Uri.parse(url));
      print('GET Response - Status: ${getResponse.statusCode}');
      print('Content-Length: ${getResponse.bodyBytes.length} bytes');

    } catch (e) {
      print('HTTP Request Error: $e');
    }
    return const Icon(Icons.error);
  }

  // Funkcija za promjenu taba
  void _onTabSelected(int index) {
    setState(() {
      _searchQuery = '';
      _selectedTabIndex = index;
    });
  }

  List<QueryDocumentSnapshot> _sortSalonsByCity(
    List<QueryDocumentSnapshot> salons,
  ) {
    if (_selectedCity == null) return salons;

    return salons.where((salon) {
      var salonData = salon.data() as Map<String, dynamic>;
      String grad = salonData['grad'] ?? '';
      return grad == _selectedCity;
    }).toList();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      context.go('/login');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Došlo je do greške prilikom odjave: $e')),
      );
    }
  }

  void _showMyAppointments(BuildContext context) async {
    if (_isAppointmentsModalShowing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morate biti prijavljeni da vidite svoje termine')),
      );
      return;
    }

    _isAppointmentsModalShowing = true;

    // Show empty modal immediately with loading indicator
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ).then((_) => _isAppointmentsModalShowing = false);

    try {
      // Fetch data in background
      final appointments = await FirebaseFirestore.instance
          .collection('termini')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> enrichedAppointments = [];

      for (var appointment in appointments.docs) {
        final data = appointment.data();
        final salonId = data['salonId'];
        String salonName = 'Nepoznat salon';

        if (salonId != null) {
          final salonDoc = await FirebaseFirestore.instance
              .collection('saloni')
              .doc(salonId)
              .get();
          if (salonDoc.exists) {
            salonName = salonDoc.data()?['naziv'] ?? 'Nepoznat salon';
          }
        }

        enrichedAppointments.add({
          ...data,
          'id': appointment.id,
          'salonName': salonName,
          'isPast': _isPastAppointment(data['datum'], data['vrijeme']),
        });
      }

      // Replace loading modal with content
      if (context.mounted) {
        Navigator.pop(context); // Remove loading modal
        _showAppointmentsContent(context, enrichedAppointments);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Došlo je do greške: $e')),
        );
      }
      _isAppointmentsModalShowing = false;
    }
  }

  void _showAppointmentsContent(BuildContext context, List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      showModalBottomSheet(
        context: context,
        builder: (context) => const Center(child: Text('Nemate zakazanih termina')),
      ).then((_) => _isAppointmentsModalShowing = false);
      return;
    }

    appointments.sort((a, b) {
      try {
        final aDate = _parseAppointmentDate(a['datum']);
        final bDate = _parseAppointmentDate(b['datum']);
        return bDate.compareTo(aDate);
      } catch (e) {
        return 0;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Moje rezervacije'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Budući termini'),
                Tab(text: 'Prošli termini'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildAppointmentsList(
                  appointments.where((a) => !a['isPast']).toList(),
                  context
              ),
              _buildAppointmentsList(
                  appointments.where((a) => a['isPast']).toList(),
                  context
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _isAppointmentsModalShowing = false);
  }

  bool _isPastAppointment(String date, String time) {
    try {
      final appointmentDate = _parseAppointmentDate(date);
      final timeFormat = DateFormat('HH:mm');
      final appointmentTime = timeFormat.parse(time);

      final appointmentDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        appointmentTime.hour,
        appointmentTime.minute,
      );

      return appointmentDateTime.isBefore(DateTime.now());
    } catch (e) {
      print('Error parsing appointment date/time: $e');
      return false;
    }
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments, BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(
        child: Text('Nema termina u ovoj kategoriji'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['salonName'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${appointment['datum']} u ${appointment['vrijeme']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (appointment['worker'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Frizerski radnik: ${appointment['worker']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Usluga: ${appointment['ime']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cijena: ${appointment['cijena'] ?? 'Nepoznata cijena'} KM',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (appointment['isPast']) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _rateAppointment(context, appointment['id']),
                    child: const Text('Ocijenite uslugu'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _rateAppointment(BuildContext context, String appointmentId) {
    // TODO: Implement rating functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocijenite uslugu'),
        content: const Text('Ovdje možete dodati ocjenu i komentar za uslugu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Frizerski saloni",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF26A69A), // Teal color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMyAppointments(context),
            tooltip: 'Moje rezervacije',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _logout(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                Container(
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
                const SizedBox(
                  height: 16,
                ), // Razmak između search field-a i dropdown-a
                // Dropdown za izbor grada
                Container(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'Izaberi grad',
                        border: InputBorder.none, // Uklanjamo defaultni border
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      items: [
                        // Dodajemo opciju za poništavanje izbora
                        const DropdownMenuItem<String>(
                          value: null, // Postavljamo vrednost na null
                          child: Text(
                            'Svi gradovi',
                            style: TextStyle(
                              color: Colors.grey,
                            ), // Siva boja za ovu opciju
                          ),
                        ),
                        ...CitiesList.cities.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(
                              city,
                              style: TextStyle(
                                color:
                                    _selectedCity == city
                                        ? const Color(
                                          0xFF26A69A,
                                        ) // Promena boje za izabrani grad
                                        : Colors.black,
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCity =
                              newValue; // Postavljamo _selectedCity na null ako je izabrana opcija "Svi gradovi"
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    'Svi Saloni',
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
                    'Preporučeni',
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
                    'Omiljeni',
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
                      String grad = salonData['grad'] ?? '';

                      // Filtriraj po pretrazi
                      if (_searchQuery.isNotEmpty &&
                          !naziv.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          )) {
                        return false;
                      }

                      // Filtriraj po izabranom gradu
                      if (_selectedCity != null && grad != _selectedCity) {
                        return false;
                      }

                      // Filtriraj po tabu (Following, Popular, Recent)
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
                          Navigator.push(
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
                                  color: const Color(0xFF26A69A).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: FutureBuilder(
                                  future: FirebaseStorage.instance
                                      .ref('salon_logos/1742902410946.jpg')
                                      .getDownloadURL(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasError) {
                                      print('Error getting download URL: ${snapshot.error}');
                                      return const Icon(Icons.error);
                                    }

                                    if (snapshot.hasData) {
                                      final url = snapshot.data!;
                                      print('Using image URL: $url');

                                      return Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: progress.expectedTotalBytes != null
                                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Image load error: $error');
                                          return const Icon(Icons.broken_image);
                                        },
                                      );
                                    }

                                    return const Icon(Icons.store);
                                  },
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
