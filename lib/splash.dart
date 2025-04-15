import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();


    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        context.go(user == null ? '/login' : '/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Svijetlo bijela/siva pozadina
      body: Stack(
        children: [
          // Logo na sredini
          Center(
            child: Image.asset(
              'assets/icons/logo.png',
              height: 220, // Povećan logo
              width: 220,
              fit: BoxFit.contain,
            ),
          ),

          // Tekst pri dnu ekrana
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "SalonTime",
                  style: GoogleFonts.roboto(
                    fontSize: 36,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Brže do savršenog izgleda",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}