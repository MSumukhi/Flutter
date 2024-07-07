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
Future<Map<String, dynamic>?> getPatientData() async {
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
          return patient;
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
  return null;
}

// Function to update WebChart with Health Data
Future<void> updateWebChartWithHealthData(String patientId, double height, double weight) async {
  if (bearerToken != null) {
    try {
      final List<Map<String, dynamic>> observations = [
        {
          'pat_id': patientId,
          'obs_name': 'BODY HEIGHT',
          'obs_result': height.toStringAsFixed(2),
          'obs_units': 'ft',
          'observed_datetime': DateTime.now().toIso8601String()
        },
        {
          'pat_id': patientId,
          'obs_name': 'BODY WEIGHT',
          'obs_result': weight.toStringAsFixed(2),
          'obs_units': 'lbs',
          'observed_datetime': DateTime.now().toIso8601String()
        }
      ];

      // Print the observations before sending the request
      print('Observations to be sent: ${jsonEncode(observations)}');

      final response = await http.put(
        Uri.parse('$apiUrl/UFVUL2RiL29ic2VydmF0aW9ucw=='), // Base64 encoded URL
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'observations': observations}),
      );

      print('Update WebChart data response status code: ${response.statusCode}');
      print('Update WebChart data response body: ${response.body}');
    } catch (e) {
      print('Error updating WebChart data: $e');
    }
  } else {
    print('Bearer token not available. Cannot update WebChart data.');
  }
}

// Function to get vitals data by Name
Future<List<Map<String, dynamic>>> getVitalsDataByName(String patientId) async {
  List<Map<String, dynamic>> vitals = [];
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
        print('Raw observations: ${observations}');

        final Map<String, String> vitalNames = {
          'BODY HEIGHT': 'Height',
          'BODY WEIGHT': 'Weight',
          'BMI': 'BMI',
          // Add other mappings as needed
        };

        for (var observation in observations) {
          if (observation['pat_id'] == patientId) {
            String? name = vitalNames[observation['obs_name']];
            if (name != null) {
              vitals.add({
                'name': name,
                'obs_name': observation['obs_name'],
                'result': double.tryParse(observation['obs_result'])?.toStringAsFixed(2) ?? observation['obs_result'],
                'date': observation['observed_datetime'],
                'units': observation['obs_units']
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error retrieving vitals by Name: $e');
    }
  }
  return vitals;
}

// Function to get vitals data by LOINC
Future<List<Map<String, dynamic>>> getVitalsDataByLOINC(String patientId) async {
  List<Map<String, dynamic>> vitals = [];
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
        print('Raw observations: ${observations}');

        final Map<String, String> loincCodes = {
          '8302-2': 'Height',
          '29463-7': 'Weight',
          '39156-5': 'BMI',
          // Add other LOINC mappings as needed
        };

        for (var observation in observations) {
          if (observation['pat_id'] == patientId) {
            String? name = loincCodes[observation['obs_code']];
            if (name != null) {
              vitals.add({
                'name': name,
                'result': double.tryParse(observation['obs_result'])?.toStringAsFixed(2) ?? observation['obs_result'],
                'date': observation['observed_datetime'],
                'units': observation['obs_units']
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error retrieving vitals by LOINC: $e');
    }
  }
  return vitals;
}
