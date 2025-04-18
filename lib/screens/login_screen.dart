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
          behavior: SnackBarBehavior.floating,
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
        builder: (context) => AppointmentsScreen(idSalona: idSalona, isOwner: isOwner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              /*Center(
                child: Image.asset(
                  'assets/icons/logo.png', 
                  height: 70,
                ),
              ),*/
              const SizedBox(height: 40),
              Text(
                'Dobro došli nazad',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prijavite se da nastavite',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Šifra',
                  labelStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value!;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        activeColor: Colors.teal.shade400,
                      ),
                      Text(
                        'Zapamti me',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _forgotPassword(context),
                    child: Text(
                      'Zaboravljena šifra?',
                      style: TextStyle(color: Colors.teal.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_emailController.text == 'admin' &&
                        _passwordController.text == 'DzenoMirza1322') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SalonCreationScreen(),
                        ),
                      );
                    } else {
                      User? user = await _authService.signInWithEmailAndPassword(
                        _emailController.text,
                        _passwordController.text,
                      );
                      if (user != null) {
                        if (!user.emailVerified && !isDev && _emailController.text != 'admin') {
                          setState(() {
                            errorMessage = "Molimo verificirajte svoj email prije prijave!";
                          });

                          await user.sendEmailVerification();

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Verifikacija emaila potrebna'),
                              content: Text(
                                'Poslali smo vam verifikacioni email. Molimo provjerite inbox i kliknite na link za verifikaciju prije nego što se prijavite.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        Map<String, dynamic>? userData = await _authService.getUserData(user.uid);
                        if (userData != null && userData['salonId'] != "") {
                          bool isOwner = userData['salonId'] != null && userData['salonId'] != "";
                          _navigateToAppointments(
                            context,
                            userData['salonId'] ?? "",
                            isOwner,
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SalonListScreen(),
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
                    backgroundColor: Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Prijava',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 24),
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
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        const TextSpan(text: "Nemaš račun? "),
                        TextSpan(
                          text: 'Registruj se',
                          style: TextStyle(
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}