import 'package:flutter/material.dart';
import 'patient.dart'; // Import the Patient model

class PatientListScreen extends StatelessWidget {
  final List<Patient> patients;

  const PatientListScreen({Key? key, required this.patients}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient List'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Adjusted for better readability
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 3/2,
        ),
        itemCount: patients.length,
        itemBuilder: (_, index) {
          return Card(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${patients[index].firstName} ${patients[index].lastName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('ID: ${patients[index].id}', style: TextStyle(color: Colors.grey[600])),
                  Text('Address: ${patients[index].address1}, ${patients[index].city}, ${patients[index].state} ${patients[index].zipCode}'),
                  Text('Email: ${patients[index].email}'),
                  Text('Birth Date: ${patients[index].birthDate}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
