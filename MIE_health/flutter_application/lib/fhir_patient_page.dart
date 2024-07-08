import 'package:flutter/material.dart';
import 'dart:convert'; // Import dart:convert for JsonEncoder

class FhirPatientPage extends StatelessWidget {
  final Map<String, dynamic> fhirData;

  const FhirPatientPage({super.key, required this.fhirData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FHIR Patient Resource'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            _formatJson(fhirData),
            style: TextStyle(fontSize: 16, fontFamily: 'Courier'),
          ),
        ),
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}
