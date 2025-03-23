import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Dodajte ovaj import
import 'package:frizerski_salon/screens/AppointmentsScreen.dart';
import 'package:frizerski_salon/screens/SalonList.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/booking_screen.dart';
import 'splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully'); // Debug log
  } catch (e) {
    print('Error initializing Firebase: $e'); // Debug log
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

// Funkcija za dohvaćanje korisničkih podataka iz Firestore-a
Future<Map<String, dynamic>?> getUserData(String uid) async {
  try {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return snapshot.data();
    } else {
      return null;
    }
  } catch (e) {
    print('Error fetching user data: $e');
    return null;
  }
}

void _navigateToAppointments(
  BuildContext context,
  String idSalona,
  bool isOwner,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => AppointmentsScreen(
            idSalona: idSalona,
            isOwner: isOwner, // Pass the isOwner value
          ),
    ),
  );
}

final GoRouter router = GoRouter(
  initialLocation: '/splash', // Set initial route to Splash screen
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => Splash(), // Splash screen
    ),
    GoRoute(
      path: '/',
      builder: (context, state) {
        final user = FirebaseAuth.instance.currentUser;
        print('User: $user'); // Debug log

        if (user == null) {
          // Ako korisnik nije prijavljen, preusmjeri na LoginScreen
          return LoginScreen();
        } else {
          // Ako je korisnik prijavljen, koristi FutureBuilder za asinkrono učitavanje podataka
          return FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(user.uid), // Dohvati korisničke podatke
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Prikaži indikator učitavanja dok se podaci učitavaju
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                // Prikaži poruku o grešci ako je došlo do problema
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data == null) {
                // Ako nema podataka, preusmjeri na SalonListScreen
                return SalonListScreen();
              } else {
                final userData = snapshot.data!;
                if (userData['salonId'] != null && userData['salonId'] != "") {
                  bool isOwner =
                      userData['salonId'] != null && userData['salonId'] != "";
                  print('User is owner: $isOwner'); // Debugging
                  var salonId = userData['salonId'];

                  // Preusmjeri na AppointmentsScreen sa salonId i isOwner vrijednostima
                  return AppointmentsScreen(
                    idSalona:
                        userData['salonId'] ??
                        "", // Ispravno prosljeđivanje imenovanog parametra
                    isOwner:
                        isOwner, // Ispravno prosljeđivanje imenovanog parametra
                  );
                } else {
                  // Preusmjeri na SalonListScreen ako korisnik nema salonId
                  return SalonListScreen();
                }
              }
            },
          );
        }
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(), // Login screen
    ),
    GoRoute(
      path: '/booking',
      builder: (context, state) => BookingScreen(), // Booking screen
    ),
  ],
);
