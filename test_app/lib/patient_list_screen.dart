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
          crossAxisCount: 2, // Adjust column count as needed
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3 / 2, // Adjust aspect ratio for better layout
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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('ID: ${patients[index].id}'),
                  if (patients[index].address1 != null && patients[index].address1!.isNotEmpty)
                    Text('Address: ${patients[index].address1}, ${patients[index].city}'),
                  if (patients[index].email != null && patients[index].email!.isNotEmpty)
                    Text('Email: ${patients[index].email}'),
                  if (patients[index].birthDate != null && patients[index].birthDate!.isNotEmpty)
                    Text('Birth Date: ${patients[index].birthDate}'),
                  if (patients[index].phone != null && patients[index].phone!.isNotEmpty)
                    Text('Phone: ${patients[index].phone}'),
                  if (patients[index].employerName != null && patients[index].employerName!.isNotEmpty)
                    Text('Employer: ${patients[index].employerName}'),
                  if (patients[index].state != null && patients[index].state!.isNotEmpty)
                    Text('State: ${patients[index].state}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
