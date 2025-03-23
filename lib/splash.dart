import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';  // Moderni fontovi
import 'package:lottie/lottie.dart';  // Animirana pozadina

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    // Postavljanje status bara na providan
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Fullscreen mod
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Timer za navigaciju
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
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animirana pozadina
          Lottie.asset(
            'assets/lottie/animation2.json',  // Postavi putanju do Lottie fajla
            fit: BoxFit.cover,
          ),

          // Tamni overlay za bolji kontrast
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Efekat zamagljenog stakla
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ikona ili logo
                      /*Icon(
                        Icons.scissors,
                        size: 70,
                        color: Colors.white.withOpacity(0.9),
                      ),*/
                      const SizedBox(height: 15),

                      // Naslov aplikacije
                      Text(
                        "SalonTime",
                        style: GoogleFonts.roboto(
                          fontSize: 36,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Slogan
                      Text(
                        "Brže do savršenog izgleda",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 50),  // Povećano sa 30 na 50

                      // Loading indikator
                      CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}