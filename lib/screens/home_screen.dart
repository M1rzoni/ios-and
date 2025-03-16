import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthService.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dohvaćanje trenutnog korisnika
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Frizerski salon'),
        actions: [
          // Dodajemo gumb za odjavu ako je korisnik prijavljen
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Odjavi se',
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  GoRouter.of(context).go('/login');
                }
              },
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prikaz informacija o korisniku ako je prijavljen
            if (isLoggedIn) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Prijavljeni ste kao: ${currentUser.displayName ?? "Korisnik"}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (currentUser.photoURL != null) ...[
                      const SizedBox(height: 12),
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(currentUser.photoURL!),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text('Email: ${currentUser.email ?? ""}'),
                  ],
                ),
              ),
              // Gumb za zakazivanje termina
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/booking'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Zakaži termin'),
              ),
            ] else ...[
              // Ako korisnik nije prijavljen, prikazujemo poruku
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Niste prijavljeni',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Prijavite se kako biste mogli zakazati termin'),
                  ],
                ),
              ),
              // Gumb za prijavu
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Prijavi se'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
