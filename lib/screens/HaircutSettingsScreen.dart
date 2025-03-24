import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Za rad s datumima

class HaircutSettingsScreen extends StatefulWidget {
  final String salonId;

  const HaircutSettingsScreen({super.key, required this.salonId});

  @override
  _HaircutSettingsScreenState createState() => _HaircutSettingsScreenState();
}

class _HaircutSettingsScreenState extends State<HaircutSettingsScreen> {
  final TextEditingController _haircutTypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _alertController = TextEditingController();
  DateTime? _expirationDate;

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Frizura je dodana!')),
    );
  }

  Stream<QuerySnapshot> _getHaircutsStream() {
    return FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .snapshots();
  }

  Stream<QuerySnapshot> _getAlertsStream() {
    return FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .snapshots();
  }

  Widget _buildHaircutsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getHaircutsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nema dostupnih frizura.'));
        }

        final haircuts = snapshot.data!.docs;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Vrsta frizure')),
                DataColumn(label: Text('Cijena (KM)')),
                DataColumn(label: Text('Akcije')),
              ],
              rows: haircuts.map((haircut) {
                return DataRow(
                  cells: [
                    DataCell(Text(haircut['type'])),
                    DataCell(Text(haircut['price'])),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editHaircut(haircut.id, haircut['type'], haircut['price']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHaircut(haircut.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAlertsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nema dostupnih alarmova.'));
        }

        final alerts = snapshot.data!.docs;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Tekst alarma')),
                DataColumn(label: Text('Datum isteka')),
                DataColumn(label: Text('Akcije')),
              ],
              rows: alerts.map((alert) {
                return DataRow(
                  cells: [
                    DataCell(Text(alert['text'])),
                    DataCell(Text(DateFormat('dd/MM/yyyy').format((alert['expirationDate'] as Timestamp).toDate()))),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editAlert(alert.id, alert['text'], alert['expirationDate']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAlert(alert.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _editHaircut(String id, String type, String price) {
    _haircutTypeController.text = type;
    _priceController.text = price;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uredi frizuru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _haircutTypeController,
                decoration: const InputDecoration(labelText: 'Vrsta frizure'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Cijena'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('saloni')
                    .doc(widget.salonId)
                    .collection('haircuts')
                    .doc(id)
                    .update({
                  'type': _haircutTypeController.text.trim(),
                  'price': _priceController.text.trim(),
                });
                Navigator.pop(context);
                _haircutTypeController.clear();
                _priceController.clear();
              },
              child: const Text('Spremi'),
            ),
          ],
        );
      },
    );
  }

  void _deleteHaircut(String id) async {
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('haircuts')
        .doc(id)
        .delete();
  }

  void _editAlert(String id, String text, DateTime expirationDate) {
    _alertController.text = text;
    _expirationDate = expirationDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uredi alarm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _alertController,
                decoration: const InputDecoration(labelText: 'Tekst alarma'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _expirationDate == null
                      ? 'Odaberite datum isteka'
                      : 'Datum isteka: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('saloni')
                    .doc(widget.salonId)
                    .collection('alerts')
                    .doc(id)
                    .update({
                  'text': _alertController.text.trim(),
                  'expirationDate': _expirationDate,
                });
                Navigator.pop(context);
                _alertController.clear();
                setState(() {
                  _expirationDate = null;
                });
              },
              child: const Text('Spremi'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAlert(String id) async {
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .doc(id)
        .delete();
  }

  void _addAlert() async {
    final String alertText = _alertController.text.trim();

    if (alertText.isEmpty || _expirationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite tekst alarma i datum isteka.')),
      );
      return;
    }

    // Add alert to Firestore
    await FirebaseFirestore.instance
        .collection('saloni')
        .doc(widget.salonId)
        .collection('alerts')
        .add({
      'text': alertText,
      'expirationDate': _expirationDate,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Clear input fields
    _alertController.clear();
    setState(() {
      _expirationDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alarm je dodan!')),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
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
                child: SingleChildScrollView(
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
                            ),
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
                      const SizedBox(height: 32),
                      const Text(
                        'Dodane frizure',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      _buildHaircutsTable(),
                      const SizedBox(height: 32),
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
                          controller: _alertController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Tekst alarma',
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: 'Unesite tekst alarma',
                            hintStyle: TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Date Picker
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
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
                        child: Text(
                          _expirationDate == null
                              ? 'Odaberite datum isteka'
                              : 'Datum isteka: ${DateFormat('dd/MM/yyyy').format(_expirationDate!)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add Alert Button
                      ElevatedButton(
                        onPressed: _addAlert,
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
                          'Dodaj alarm',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Dodani alarmi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      _buildAlertsTable(),
                    ],
                  ),
                ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}