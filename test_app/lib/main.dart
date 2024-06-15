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
        final patient = patients.firstWhere((patient) => patient['pat_id'] == '18', orElse: () => null);
        if (patient != null) {
          print('Patient ID: ${patient['pat_id']}');
          print('First Name: ${patient['first_name']}');
          print('Last Name: ${patient['last_name']}');
          print('Email: ${patient['email']}');
          print('Birth Date: ${patient['birth_date']}');
          print('Phone: ${patient['cell_phone']}');
          print('--------------------------------');

          await getVitalsData(patient['pat_id']);
        } else {
          print('Patient with ID 18 not found');
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

// Mapping of observation names from the database to the expected vital names
const Map<String, String> observationNameMapping = {
  'BODY HEIGHT': 'Height',
  'BODY WEIGHT': 'Weight',
  'BODY TEMPERATURE': 'Temp',
  'HEART RATE': 'Pulse',
  'RESPIRATION RATE': 'Resp',
  'BMI': 'BMI',
  'Systolic BP': 'Blood Pressure',
  'Diastolic BP': 'Blood Pressure',
  'O2 Sat': 'O2 Sat',
  'Head Circ': 'Head Circ',
  'Waist Circ': 'Waist Circ'
};

// Function to retrieve vitals data
Future<void> getVitalsData(String patientId) async {
  if (bearerToken != null) {
    try {
      final String encodedOperation = base64Encode(utf8.encode('GET/db/observations'));

      final response = await http.get(
        Uri.parse('$apiUrl/$encodedOperation'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
      );

      print('Get vitals data response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> observations = jsonDecode(response.body)['db'];
        
        // Filter and map observations to vitals
        final List<Map<String, dynamic>> vitals = observations
            .where((obs) => obs['pat_id'] == patientId &&
                observationNameMapping.containsKey(obs['obs_name']))
            .map((obs) => {
                  'name': observationNameMapping[obs['obs_name']],
                  'result': obs['obs_result'],
                  'date': obs['observed_datetime'],
                  'units': obs['obs_units'] ?? ''
                })
            .toList();

        // Sort vitals by observed_datetime and keep only the latest entry for each vital type
        Map<String, Map<String, dynamic>> latestVitals = {};
        for (var vital in vitals) {
          if (!latestVitals.containsKey(vital['name']) || DateTime.parse(latestVitals[vital['name']]!['date']).isBefore(DateTime.parse(vital['date']))) {
            latestVitals[vital['name']] = vital;
          }
        }

        // Print vitals
        print('\nVitals:');
        final vitalNames = ['Height', 'Weight', 'BMI', 'Blood Pressure', 'Pulse', 'Temp', 'Resp', 'O2 Sat', 'Head Circ', 'Waist Circ'];
        for (var name in vitalNames) {
          if (latestVitals.containsKey(name)) {
            var vital = latestVitals[name]!;
            print('$name: ${vital['result']} ${vital['units']} (${vital['date']})');
          } else {
            print('$name:');
          }
        }
      } else {
        print('Failed to retrieve vitals data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving vitals data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for vitals data.');
  }
}

void main() async {
  // Provide your username and password here
  final String username = 'Sumu1231';
  final String password = 'Sumukhi@1231';

  await authenticateUser(username, password);
  await getPatientData();
}
