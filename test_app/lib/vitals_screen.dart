import 'package:flutter/material.dart';
import 'patient.dart'; // Import the Patient model

class VitalsScreen extends StatelessWidget {
  final Patient patient;

  const VitalsScreen({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('First Name: ${patient.firstName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Last Name: ${patient.lastName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Email: ${patient.email}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Birth Date: ${patient.birthDate}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Phone: ${patient.phone}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 20),
            Text('Vitals:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...patient.vitals.map((vital) => Text('${vital.name}: ${vital.result} ${vital.units} (${vital.dateTime})')),
          ],
        ),
      ),
    );
  }
}
