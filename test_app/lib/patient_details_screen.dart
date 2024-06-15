import 'package:flutter/material.dart';
import 'patient.dart'; // Import the Patient model

class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailsScreen({Key? key, required this.patient}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient ID: ${patient.id}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'First Name: ${patient.firstName}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Last Name: ${patient.lastName}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            if (patient.address1 != null && patient.address1!.isNotEmpty)
              Text(
                'Address: ${patient.address1}, ${patient.city}, ${patient.state} ${patient.zipCode}',
                style: TextStyle(fontSize: 18),
              ),
            if (patient.email != null && patient.email!.isNotEmpty)
              Text(
                'Email: ${patient.email}',
                style: TextStyle(fontSize: 18),
              ),
            if (patient.birthDate != null && patient.birthDate!.isNotEmpty)
              Text(
                'Birth Date: ${patient.birthDate}',
                style: TextStyle(fontSize: 18),
              ),
            if (patient.phone != null && patient.phone!.isNotEmpty)
              Text(
                'Phone: ${patient.phone}',
                style: TextStyle(fontSize: 18),
              ),
            if (patient.employerName != null && patient.employerName!.isNotEmpty)
              Text(
                'Employer: ${patient.employerName}',
                style: TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}
