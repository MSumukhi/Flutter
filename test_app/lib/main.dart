import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'patient.dart';
import 'patient_list_screen.dart';

// Define apiUrl globally
final String apiUrl = 'https://sumukhi.webch.art/webchart.cgi/json';
// Define bearerToken globally, making it nullable and initialized as null
String? bearerToken;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<List<Patient>>(
        future: authenticateAndGetPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return PatientListScreen(patients: snapshot.data!);
            } else {
              return Center(child: Text('Failed to load patients'));
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

Future<List<Patient>> authenticateAndGetPatients() async {
  await authenticateUser('Sumu1231', 'Sumukhi@1231');
  return await getPatientData();
}

Future<void> authenticateUser(String username, String password) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {'login_user': username, 'login_passwd': password},
  );

  if (response.statusCode == 200 && response.headers['set-cookie'] != null) {
    final setCookieHeader = response.headers['set-cookie']!;
    bearerToken = setCookieHeader.split('=')[1].split(';')[0];
  }
}

Future<List<Patient>> getPatientData() async {
  List<Patient> patientList = [];
  if (bearerToken != null) {
    final String encodedOperation = base64Encode(utf8.encode('GET/db/patients'));
    final response = await http.get(
      Uri.parse('$apiUrl/$encodedOperation'),
      headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> patientsJson = jsonDecode(response.body)['db'];
      patientList = patientsJson.map((json) => Patient.fromJson(json)).toList();
    }
  }
  return patientList;
}
