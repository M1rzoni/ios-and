import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frizerski_salon/screens/AppointmentsScreen.dart';
import 'package:frizerski_salon/screens/SalonCreationScreen.dart';
import 'package:frizerski_salon/screens/SalonList.dart';
import 'AuthService.dart';
import 'RegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = "";
  bool rememberMe = false;
  bool _obscurePassword = true;
  bool isDev = true;

  Future<void> _forgotPassword(BuildContext context) async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage = "Molimo unesite vašu email adresu.";
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email za resetovanje lozinke je poslan. Provjerite svoj inbox.',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage =
            "Slanje emaila za resetovanje lozinke nije uspjelo. Provjerite vašu email adresu.";
      });
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
            (context) =>
                AppointmentsScreen(idSalona: idSalona, isOwner: isOwner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Prijava',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite vašu email adresu',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Šifra',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          TextField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unesite vašu šifru',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _forgotPassword(context);
                        },
                        child: Text(
                          'Zaboravljena šifra?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value!;
                            });
                          },
                          checkColor: Color(0xFF26A69A),
                          fillColor: WidgetStateProperty.resolveWith(
                            (states) => Colors.white,
                          ),
                        ),
                        Text(
                          'Zapamti me',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_emailController.text == 'admin' &&
                                  _passwordController.text == 'admin') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const SalonCreationScreen(),
                                  ),
                                );
                              } else {
                                User? user = await _authService
                                    .signInWithEmailAndPassword(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                if (user != null) {
                                  // Provjera da li je korisnik admin ili ima verificiran email
                                  if (!user.emailVerified &&
                                      !isDev &&
                                      _emailController.text != 'admin') {
                                    setState(() {
                                      errorMessage =
                                          "Molimo verificirajte svoj email prije prijave!";
                                    });

                                    await user.sendEmailVerification();

                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: Text(
                                              'Verifikacija emaila potrebna',
                                            ),
                                            content: Text(
                                              'Poslali smo vam verifikacioni email. Molimo provjerite inbox i kliknite na link za verifikaciju prije nego što se prijavite.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                    return;
                                  }

                                  Map<String, dynamic>? userData =
                                      await _authService.getUserData(user.uid);
                                  if (userData != null &&
                                      userData['salonId'] != "") {
                                    bool isOwner =
                                        userData['salonId'] != null &&
                                        userData['salonId'] != "";
                                    _navigateToAppointments(
                                      context,
                                      userData['salonId'] ?? "",
                                      isOwner,
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const SalonListScreen(),
                                      ),
                                    );
                                  }
                                } else {
                                  setState(() {
                                    errorMessage = "Prijava nije uspjela!";
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Prijavi se'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(text: "Nemaš račun? "),
                              TextSpan(
                                text: 'Registruj se',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.g_mobiledata, size: 24),
                            onPressed: () async {
                              User? user =
                                  await _authService.signInWithGoogle();
                              if (user != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SalonListScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.apple, size: 24),
                            onPressed: () {
                              // Add Apple sign in functionality here
                            },
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red.shade100),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
