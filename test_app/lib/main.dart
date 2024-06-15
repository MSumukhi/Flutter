import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'patient.dart';
import 'patient_details_screen.dart';

final String apiUrl = 'https://sumukhi.webch.art/webchart.cgi/json';
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
  bool _isLoading = false;
  String _errorMessage = '';

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Authenticate and get patient
    final patient = await authenticateAndGetPatient(username, password);

    setState(() {
      _isLoading = false;
    });

    if (patient != null) {
      // Navigate to PatientDetailsScreen with the fetched patient
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patient: patient),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    }
  }

  Future<void> authenticateUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'login_user': username, 'login_passwd': password},
      );

      if (response.statusCode == 200 && response.headers['set-cookie'] != null) {
        final setCookieHeader = response.headers['set-cookie']!;
        bearerToken = setCookieHeader.split('=')[1].split(';')[0];
      } else {
        print('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during authentication: $e');
    }
  }

  Future<Patient?> authenticateAndGetPatient(String username, String password) async {
    await authenticateUser(username, password);
    return await getPatientData();
  }

  Future<Patient?> getPatientData() async {
    if (bearerToken != null) {
      try {
        final String encodedOperation = base64Encode(utf8.encode('GET/db/patients'));

        final response = await http.get(
          Uri.parse('$apiUrl/$encodedOperation'),
          headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> patients = jsonDecode(response.body)['db'];
          final patientJson = patients.firstWhere((patient) => patient['pat_id'] == '111', orElse: () => null);
          if (patientJson != null) {
            return Patient.fromJson(patientJson);
          }
        }
      } catch (e) {
        print('Error retrieving patient data: $e');
      }
    } else {
      print('Bearer token not available. Cannot make request for patient data.');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Container(
          width: 400,
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Login'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
