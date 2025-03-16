import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream za praćenje statusa korisnika
  Stream<User?> get userStream => _auth.authStateChanges();

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Greška prilikom dohvaćanja korisničkih podataka: $e");
      return null;
    }
  }

  // 🔹 Registracija korisnika emailom i lozinkom
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String fullName,
      String phoneNumber,
      ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      print("User registered: ${userCredential.user?.email}");

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'salonId': '',
      });

      return userCredential.user;
    } catch (e) {
      print("Greška prilikom registracije: $e");
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User logged in: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      print("Greška prilikom prijave: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In cancelled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print("User logged in with Google: ${userCredential.user?.email}");
      return userCredential.user;
    } catch (e) {
      print("Greška prilikom prijave putem Google-a: $e");
      return null;
    }
  }

  // 🔹 Odjava korisnika
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
