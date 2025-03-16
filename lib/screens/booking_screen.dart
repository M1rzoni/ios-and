import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AppointmentsScreen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedService;
  double? _selectedPrice;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final Map<String, double> _servicePrices = {
    'Šišanje': 13.0,
    'Brijanje': 7.0,
    'Šišanje + Brada': 18.0,
  };

  final List<String> _services = ['Šišanje', 'Brijanje', 'Šišanje + Brada'];

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      if (pickedDate.weekday == 6 || pickedDate.weekday == 7) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Možete zakazati samo od ponedjeljka do petka!'),
          ),
        );
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );

    if (pickedTime != null) {
      if (pickedTime.hour < 9 || pickedTime.hour >= 17) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Radno vrijeme je od 09:00 do 17:00!')),
        );
        return;
      }
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _saveBooking() async {
    if (_nameController.text.isEmpty ||
        _selectedService == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo popunite sva polja!')),
      );
      return;
    }

    String formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDate!);
    String formattedTime = _selectedTime!.format(context);

    await FirebaseFirestore.instance.collection('termini').add({
      'ime': _nameController.text,
      'usluga': _selectedService,
      'cijena': _selectedPrice,
      'datum': formattedDate,
      'vrijeme': formattedTime,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Termin uspješno zakazan!')));

    _nameController.clear();
    setState(() {
      _selectedService = null;
      _selectedPrice = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _navigateToAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointmentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zakazivanje termina')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Vaše ime'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedService,
              items:
                  _services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                  _selectedPrice = _servicePrices[value];
                });
              },
              decoration: const InputDecoration(labelText: 'Odaberite uslugu'),
            ),
            if (_selectedPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Cijena: ${_selectedPrice!.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickDate,
                    child: Text(
                      _selectedDate == null
                          ? 'Odaberite datum'
                          : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    child: Text(
                      _selectedTime == null
                          ? 'Odaberite vrijeme'
                          : _selectedTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _saveBooking,
                child: const Text('Potvrdi termin'),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _navigateToAppointments,
                child: const Text('Prikaži rezervisane termine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
