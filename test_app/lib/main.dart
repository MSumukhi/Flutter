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
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Authenticate and get patients
    List<Patient> patients = await authenticateAndGetPatients(username, password);

    // Navigate to PatientListScreen with the fetched patients
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatientListScreen(patients: patients),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<Patient>> authenticateAndGetPatients(String username, String password) async {
  await authenticateUser(username, password);
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
