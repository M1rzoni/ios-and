import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Postavlja statusnu traku da bude transparentna
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Postavlja aplikaciju u fullscreen režim
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Animacija za fade-in efekt
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Tajmer za navigaciju
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        context.go(user == null ? '/login' : '/');
      }
    });
  }

  @override
  void dispose() {
    // Vraća standardnu postavku sistema nakon splash screena
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uklanja standardnu sigurnu zonu
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        // Osigurava da kontenjer zauzme ceo ekran
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF26A69A), // Teal
              Color(0xFF80CBC4), // Lighter teal
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Naslov
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Text(
                "Dino's Barber Shop",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Lottie animacija
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Container(
                width: 250, // Smanjio sam veličinu animacije
                height: 250,
                child: Lottie.asset(
                  "assets/lottie/animation.json",
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Spacer(flex: 1),
            // Dodatni tekst na dnu
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Text(
                "Cutting Edge Style",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
