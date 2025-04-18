import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:frizerski_salon/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frizerski_salon/cities_list.dart';
import 'package:frizerski_salon/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'booking_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonListScreen extends StatefulWidget {
  const SalonListScreen({super.key});

  @override
  _SalonListScreenState createState() => _SalonListScreenState();
}

class _SalonListScreenState extends State<SalonListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _favoritedSalons = [];
  int _selectedTabIndex = 0;
  String? _selectedCity;
  int _currentBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFavoritedSalons();
  }

  Future<void> _loadFavoritedSalons() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final favoritedSalons = await getFavoritedSalons(userId);
    setState(() {
      _favoritedSalons = favoritedSalons;
    });
  }

  Future<List<String>> getFavoritedSalons(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();

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

  Future<void> _toggleFavorite(String salonId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    if (_favoritedSalons.contains(salonId)) {
      setState(() {
        _favoritedSalons.remove(salonId);
      });
    } else {
      setState(() {
        _favoritedSalons.add(salonId);
      });
    }

    await updateFavoritedSalons(userId, _favoritedSalons);

    final salonRef = FirebaseFirestore.instance.collection('saloni').doc(salonId);
    if (_favoritedSalons.contains(salonId)) {
      await salonRef.update({'favorites': FieldValue.increment(1)});
    } else {
      await salonRef.update({'favorites': FieldValue.increment(-1)});
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _searchQuery = '';
      _selectedTabIndex = index;
    });
  }

  List<QueryDocumentSnapshot> _sortSalonsByCity(List<QueryDocumentSnapshot> salons) {
    if (_selectedCity == null) return salons;

    return salons.where((salon) {
      var salonData = salon.data() as Map<String, dynamic>;
      String grad = salonData['grad'] ?? '';
      return grad == _selectedCity;
    }).toList();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showSalonDetails(Map<String, dynamic> salon) {
    final address = salon['adresa'] ?? 'Nema adrese';
    final encodedAddress = Uri.encodeComponent(address);
    final mapUrl = 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d22786.206229529515!2d18.606767956048003!3d44.4480160254353!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x475eb33e35e40b23%3A0x6a3fea2e9715234e!2sLaurus%20Motel!5e0!3m2!1sen!2sba!4v1744994964212!5m2!1sen!2sba';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon Header with Logo
                _buildSalonHeader(salon),
                
                // Salon Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildDetailRow(Icons.location_on, salon['adresa'] ?? 'Nema adrese'),
                      _buildDetailRow(Icons.phone, salon['brojTelefona'] ?? 'Nema broja'),
                      _buildDetailRow(Icons.person, 'Vlasnik: ${salon['vlasnik'] ?? 'Nepoznat'}'),
                      _buildDetailRow(Icons.favorite, 'Omiljeni: ${salon['favorites'] ?? 0}'),
                      
                      // Working Days
                      if (salon['workingDays'] != null && (salon['workingDays'] as List).isNotEmpty)
                        _buildWorkingDays(salon['workingDays']),
                      
                      // Working Hours
                      if (salon['workingHours'] != null)
                        _buildWorkingHours(salon['workingHours']),
                      
                      // Employees
                      if (salon['radnici'] != null && (salon['radnici'] as List).isNotEmpty)
                        _buildEmployeesList(salon['radnici']),
                      
                      const SizedBox(height: 24),
                      
                      // Map Section
                      if (address.isNotEmpty && address != 'Nema adrese')
                        _buildMapSection(mapUrl, address),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalonHeader(Map<String, dynamic> salon) {
    final logoUrl = salon['logoUrl'];
    final isWideImage = logoUrl != null && (logoUrl.contains('wide') || logoUrl.contains('landscape'));
    
    return Stack(
      children: [
        if (isWideImage && logoUrl != null)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              image: DecorationImage(
                image: NetworkImage(logoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            color: isWideImage ? Colors.black.withOpacity(0.4) : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: isWideImage ? CrossAxisAlignment.end : CrossAxisAlignment.center,
            children: [
              if (!isWideImage && logoUrl != null)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    image: DecorationImage(
                      image: NetworkImage(logoUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              
              if (!isWideImage) const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon['naziv'] ?? 'Nepoznat salon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isWideImage ? Colors.white : Colors.black,
                      ),
                    ),
                    if (salon['grad'] != null)
                      Text(
                        salon['grad'],
                        style: TextStyle(
                          fontSize: 16,
                          color: isWideImage ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingDays(List<dynamic> days) {
    final bosnianDays = {
      'Monday': 'Ponedjeljak',
      'Tuesday': 'Utorak',
      'Wednesday': 'Srijeda',
      'Thursday': 'Četvrtak',
      'Friday': 'Petak',
      'Saturday': 'Subota',
      'Sunday': 'Nedjelja',
    };
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.teal.shade600),
              const SizedBox(width: 12),
              Text(
                'Radni dani:',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: days.map((day) {
              final bosnianDay = bosnianDays[day] ?? day;
              return Chip(
                label: Text(bosnianDay),
                backgroundColor: Colors.teal.shade50,
                labelStyle: TextStyle(color: Colors.teal.shade800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHours(String hours) {
    // Convert 12h to 24h format
    String convertTo24Hour(String time12h) {
      try {
        final format12h = DateFormat('h:mm a');
        final format24h = DateFormat('HH:mm');
        final date = format12h.parse(time12h.replaceAll('.', ''));
        return format24h.format(date);
      } catch (e) {
        return time12h; // Return original if conversion fails
      }
    }

    final formattedHours = hours.split(' - ').map(convertTo24Hour).join(' - ');
    
    return _buildDetailRow(
      Icons.access_time,
      'Radno vrijeme: $formattedHours',
    );
  }

  Widget _buildEmployeesList(List<dynamic> employees) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, size: 20, color: Colors.teal.shade600),
              const SizedBox(width: 12),
              Text(
                'Radnici:',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: employees.map((employee) {
              return Chip(
                label: Text(employee),
                avatar: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    employee.substring(0, 1),
                    style: TextStyle(color: Colors.teal.shade800),
                  ),
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(String mapUrl, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map, size: 20, color: Colors.teal.shade600),
            const SizedBox(width: 12),
            Text(
              'Lokacija:',
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap?center=$address&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7C$address&key=YOUR_API_KEY',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey[400]),
                      Text('Mapa nije dostupna', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final url = 'https://www.google.com/maps/search/?api=1&query=$address';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
            icon: Icon(Icons.open_in_new, size: 16),
            label: Text('Otvori u Maps'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalonImage(String imageUrl) {
    return Stack(
      children: [
        Container(color: Colors.white),
        Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: 70,
            height: 70,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.teal.shade600,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderIcon();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.store,
        size: 36,
        color: Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Frizerski saloni",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.teal.shade600,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pretraži salone...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.teal.shade600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // City Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'Odaberi grad',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'Svi Gradovi',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ...CitiesList.cities.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(
                              city,
                              style: TextStyle(
                                color: _selectedCity == city
                                    ? Colors.teal.shade600
                                    : Colors.black,
                              ),
                            ),
                          );
                        }),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    text: 'Svi Saloni',
                    isSelected: _selectedTabIndex == 0,
                    onTap: () => _onTabSelected(0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'Popularni',
                    isSelected: _selectedTabIndex == 1,
                    onTap: () => _onTabSelected(1),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'Favoriti',
                    isSelected: _selectedTabIndex == 2,
                    onTap: () => _onTabSelected(2),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Salon List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('saloni').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal.shade600,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Nema dostupnih salona",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var salons = snapshot.data!.docs;

                var filteredSalons = salons.where((salon) {
                  var salonData = salon.data() as Map<String, dynamic>;
                  String naziv = salonData['naziv'] ?? '';
                  String grad = salonData['grad'] ?? '';

                  if (_searchQuery.isNotEmpty &&
                      !naziv.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }

                  if (_selectedCity != null && grad != _selectedCity) {
                    return false;
                  }

                  if (_selectedTabIndex == 2 && !_favoritedSalons.contains(salon.id)) {
                    return false;
                  }

                  return true;
                }).toList();

                if (_selectedTabIndex == 1) {
                  filteredSalons.sort((a, b) {
                    int aFavorites = (a.data() as Map<String, dynamic>)['favorites'] ?? 0;
                    int bFavorites = (b.data() as Map<String, dynamic>)['favorites'] ?? 0;
                    return bFavorites.compareTo(aFavorites);
                  });
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredSalons.length,
                  itemBuilder: (context, index) {
                    var salonDoc = filteredSalons[index];
                    var salon = salonDoc.data() as Map<String, dynamic>;
                    String idSalona = salonDoc.id;
                    String naziv = salon['naziv'] ?? 'Nepoznat salon';
                    String adresa = salon['adresa'] ?? 'Nema adrese';
                    String brojTelefona = salon['brojTelefona'] ?? 'Nema broja';
                    String? logoUrl = salon['logoUrl'];
                    int favorites = salon['favorites'] ?? 0;

                    return GestureDetector(
                      onLongPress: () => _showSalonDetails(salon),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingScreen(idSalona: idSalona),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Salon Logo
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: logoUrl != null && logoUrl.isNotEmpty
                                          ? _buildSalonImage(logoUrl)
                                          : _buildPlaceholderIcon(),
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
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                adresa,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              brojTelefona,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.favorite,
                                              size: 16,
                                              color: Colors.pink[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$favorites',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              icon: Icon(
                                                _favoritedSalons.contains(idSalona)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: _favoritedSalons.contains(idSalona)
                                                    ? Colors.pink[400]
                                                    : Colors.grey[400],
                                              ),
                                              onPressed: () {
                                                _toggleFavorite(idSalona);
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              iconSize: 24,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
      bottomNavigationBar: _BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() {
            _currentBottomIndex = index;
            if (index == 0) {
              // Home - do nothing, we're already here
            } else if (index == 1) {
              // My Reservations - placeholder for now
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Moje rezervacije uskoro dolaze!'),
                  backgroundColor: Colors.teal.shade600,
                ),
              );
            } else if (index == 2) {
              // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            }
          });
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade600.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.teal.shade600 : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal.shade600,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
          elevation: 8,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Početna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Moje Rezervacije',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}