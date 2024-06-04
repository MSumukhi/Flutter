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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Number of columns
          crossAxisSpacing: 4, // Horizontal space between items
          mainAxisSpacing: 4, // Vertical space between items
          childAspectRatio: 3 / 2, // Aspect ratio of each item
        ),
        itemCount: patients.length,
        itemBuilder: (_, index) {
          return Card(
            child: Container(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('${patients[index].firstName} ${patients[index].lastName}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('ID: ${patients[index].id}'),
                  // You can add more patient details here
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
