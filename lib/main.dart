import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/booking_screen.dart';
import 'splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        // Redirect to LoginScreen if user is not logged in, otherwise to HomeScreen
        return user == null ? LoginScreen() : HomeScreen();
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
