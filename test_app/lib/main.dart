import 'dart:convert';
import 'package:http/http.dart' as http;

String? bearerToken;
final String apiUrl = 'https://sumukhi.webch.art/webchart.cgi/json';

// Function to authenticate user and obtain bearer token
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

// Function to retrieve specific patient data
Future<void> getPatientData() async {
  if (bearerToken != null) {
    try {
      final String encodedOperation = base64Encode(utf8.encode('GET/db/patients'));

      final response = await http.get(
        Uri.parse('$apiUrl/$encodedOperation'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
      );

      print('Get patient data response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> patients = jsonDecode(response.body)['db'];
        final patient = patients.firstWhere((patient) => patient['pat_id'] == '111', orElse: () => null);
        if (patient != null) {
          print('Patient ID: ${patient['pat_id']}');
          print('First Name: ${patient['first_name']}');
          print('Last Name: ${patient['last_name']}');
          // Print other patient details as needed
          print('--------------------------------');
        } else {
          print('Patient with ID 111 not found');
        }
      } else {
        print('Failed to retrieve patient data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving patient data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for patient data.');
  }
}

void main() async {
  // Provide your username and password here
  final String username = 'Sumu1231';
  final String password = 'Sumukhi@1231';
  
  await authenticateUser(username, password);
  await getPatientData();
}
