import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HaircutSettingsScreen extends StatefulWidget {
  final String salonId;

  const HaircutSettingsScreen({super.key, required this.salonId});

  @override
  _HaircutSettingsScreenState createState() => _HaircutSettingsScreenState();
}

class _HaircutSettingsScreenState extends State<HaircutSettingsScreen> {
  final TextEditingController _haircutTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _addHaircutType() async {
    final String haircutType = _haircutTypeController.text.trim();
    final String price = _priceController.text.trim();

    if (haircutType.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite vrstu frizure i cijenu.')),
      );
      return;
    }

    // Add haircut type and price to Firestore
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .add({
          'type': haircutType,
          'price': price,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Clear input fields
    _haircutTypeController.clear();
    _priceController.clear();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frizura je dodana!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Postavke frizura',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Haircut Type Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _haircutTypeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Vrsta frizure',
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: 'Unesite vrstu frizure',
                            hintStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.5),
                            ), // White with 50% opacity)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _priceController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Cijena',
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: 'Unesite cijenu',
                            hintStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.5),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add Haircut Button
                      ElevatedButton(
                        onPressed: _addHaircutType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          'Dodaj frizuru',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
