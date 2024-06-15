import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'patient.dart';
import 'vitals_screen.dart';

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
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Authenticate and get patient data
    try {
      Patient patient = await authenticateAndGetPatientData(username, password);

      setState(() {
        _isLoading = false;
      });

      // Navigate to VitalsScreen with the fetched patient data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VitalsScreen(patient: patient),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Container(
          width: 400, // Fixed width for the form
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
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> authenticateUser(String username, String password) async {
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'login_user': username, 'login_passwd': password},
    );

    print('Authenticate user response status code: ${response.statusCode}');

    if (response.statusCode == 200 && response.headers['set-cookie'] != null) {
      final setCookieHeader = response.headers['set-cookie']!;
      bearerToken = setCookieHeader.split('=')[1].split(';')[0];
      print('Bearer token obtained: $bearerToken');
    } else {
      print('Authentication failed: ${response.statusCode}');
    }
  } catch (e) {
    print('Error during authentication: $e');
  }
}

Future<Patient> authenticateAndGetPatientData(String username, String password) async {
  await authenticateUser(username, password);
  return await getPatientData();
}

Future<Patient> getPatientData() async {
  if (bearerToken != null) {
    try {
      // Fetch patient demographics
      final String encodedOperationPatients = base64Encode(utf8.encode('GET/db/patients'));
      final responsePatients = await http.get(
        Uri.parse('$apiUrl/$encodedOperationPatients'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
      );

      print('Get patient data response status code: ${responsePatients.statusCode}');

      if (responsePatients.statusCode == 200) {
        final List<dynamic> patients = jsonDecode(responsePatients.body)['db'];
        final patient = Patient.fromJson(patients.firstWhere((patient) => patient['first_name'] == 'Sumukhi'));

        // Fetch patient vitals
        final String encodedOperationVitals = base64Encode(utf8.encode('GET/db/observations'));
        final responseVitals = await http.get(
          Uri.parse('$apiUrl/$encodedOperationVitals'),
          headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
        );

        print('Get vitals data response status code: ${responseVitals.statusCode}');

        if (responseVitals.statusCode == 200) {
          final List<dynamic> observations = jsonDecode(responseVitals.body)['db'];
          for (var observation in observations) {
            if (['Height', 'Weight', 'BMI', 'Blood Pressure', 'Pulse', 'Temp', 'Resp', 'O2 Sat'].contains(observation['obs_name'])) {
              patient.vitals.add(Observation.fromJson(observation));
            }
          }
        } else {
          print('Failed to retrieve vitals data: ${responseVitals.statusCode}');
        }

        return patient;
      } else {
        print('Failed to retrieve patient data: ${responsePatients.statusCode}');
      }
    } catch (e) {
      print('Error retrieving patient data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for patient data.');
  }
  throw Exception('Failed to retrieve patient data');
}
