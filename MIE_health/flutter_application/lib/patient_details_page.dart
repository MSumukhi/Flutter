import 'package:flutter/material.dart';

class PatientDetailsPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;

  const PatientDetailsPage({super.key, required this.patientData, required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Details and Vitals'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ExpansionTile(
              title: Text('Patient Details'),
              children: [
                ListTile(title: Text('ID: ${patientData['pat_id']}')),
                ListTile(title: Text('First Name: ${patientData['first_name']}')),
                ListTile(title: Text('Last Name: ${patientData['last_name']}')),
                ListTile(title: Text('Email: ${patientData['email']}')),
                ListTile(title: Text('Birth Date: ${patientData['birth_date']}')),
                ListTile(title: Text('Phone: ${patientData['cell_phone']}')),
              ],
            ),
            ExpansionTile(
              title: Text('Vitals'),
              children: vitals.map((vital) {
                return ListTile(
                  title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
