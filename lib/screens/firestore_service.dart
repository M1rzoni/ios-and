import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getSalons() async {
    try {
      QuerySnapshot snapshot = await _db.collection('saloni').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Greška pri dohvaćanju salona: $e");
      return [];
    }
  }
}
