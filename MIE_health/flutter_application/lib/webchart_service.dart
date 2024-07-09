import 'dart:convert';
import 'package:http/http.dart' as http;

String? bearerToken;
final String apiUrl = 'https://sumukhi.webch.art/webchart.cgi/json';
final String fhirApiUrl = 'https://sumukhi.webch.art/webchart.cgi/fhir';

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
Future<void> updateWebChartWithHealthData(String patientId, double height, double weight, double systolic, double diastolic, DateTime heightTimestamp, DateTime weightTimestamp, DateTime systolicTimestamp, DateTime diastolicTimestamp) async {
  if (bearerToken != null) {
    try {
      final List<Map<String, dynamic>> observations = [
        {
          'pat_id': patientId,
          'obs_name': 'BODY HEIGHT',
          'obs_result': height.toStringAsFixed(2),
          'obs_units': 'ft',
          'observed_datetime': heightTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'obs_name': 'BODY WEIGHT',
          'obs_result': weight.toStringAsFixed(2),
          'obs_units': 'lbs',
          'observed_datetime': weightTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'obs_name': 'Systolic BP',
          'obs_result': systolic.toStringAsFixed(2),
          'obs_units': 'mmHg',
          'observed_datetime': systolicTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'obs_name': 'Diastolic BP',
          'obs_result': diastolic.toStringAsFixed(2),
          'obs_units': 'mmHg',
          'observed_datetime': diastolicTimestamp.toIso8601String()
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
      if (response.statusCode == 200) {
        print('Successfully updated WebChart data.');
      } else {
        print('Failed to update WebChart data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating WebChart data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request to update WebChart data.');
  }
}

// Function to retrieve latest vitals data
Future<List<Map<String, dynamic>>> getVitalsData(String patientId) async {
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
            .where((obs) => obs['pat_id'] == patientId && observationNameMapping.containsKey(obs['obs_name']))
            .map((obs) => {
                  'name': observationNameMapping[obs['obs_name']],
                  'result': obs['obs_result'],
                  'date': obs['observed_datetime'],
                  'units': obs['obs_units'] ?? ''
                })
            .toList();

        // Ensure all vitals are present, set to zero if not found
        final Map<String, Map<String, dynamic>> latestVitals = {};
        for (var vital in vitals) {
          if (!latestVitals.containsKey(vital['name']) || DateTime.parse(latestVitals[vital['name']]!['date']).isBefore(DateTime.parse(vital['date']))) {
            latestVitals[vital['name']] = vital;
          }
        }
        final allVitals = _getDefaultVitals().map((defaultVital) {
          return latestVitals[defaultVital['name']] ?? defaultVital;
        }).toList();

        print('Retrieved vitals: $allVitals');

        return allVitals;
      } else {
        print('Failed to retrieve vitals data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving vitals data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for vitals data.');
  }
  return [];
}

// Function to retrieve FHIR Patient Resource
Future<Map<String, dynamic>?> getFhirPatientResource(String patientId) async {
  if (bearerToken != null) {
    try {
      final response = await http.get(
        Uri.parse('$fhirApiUrl/Patient/$patientId'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/fhir+json'},
      );
      print('Get FHIR patient resource response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> fhirData = jsonDecode(response.body);
        print('FHIR patient resource: $fhirData');
        return fhirData;
      } else {
        print('Failed to retrieve FHIR patient resource: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving FHIR patient resource: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for FHIR patient resource.');
  }
  return null;
}

// Function to retrieve FHIR Patient Vitals Resource
Future<Map<String, dynamic>?> getFhirPatientVitals(String patientId) async {
  if (bearerToken != null) {
    try {
      final response = await http.get(
        Uri.parse('$fhirApiUrl/Observation?category=vital-signs&patient=$patientId'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/fhir+json'},
      );
      print('Get FHIR patient vitals resource response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> fhirData = jsonDecode(response.body);
        print('FHIR patient vitals resource: $fhirData');
        return fhirData;
      } else {
        print('Failed to retrieve FHIR patient vitals resource: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving FHIR patient vitals resource: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for FHIR patient vitals resource.');
  }
  return null;
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

List<Map<String, dynamic>> _getDefaultVitals() {
  return [
    {'name': 'Height', 'result': '0', 'units': 'ft', 'date': ''},
    {'name': 'Weight', 'result': '0', 'units': 'lbs', 'date': ''},
    {'name': 'BMI', 'result': '0', 'units': '', 'date': ''},
    {'name': 'Blood Pressure', 'result': '0/0', 'units': 'mmHg', 'date': ''},
    {'name': 'Pulse', 'result': '0', 'units': '', 'date': ''},
    {'name': 'Temp', 'result': '0', 'units': '', 'date': ''},
    {'name': 'Resp', 'result': '0', 'units': '', 'date': ''},
    {'name': 'O2 Sat', 'result': '0', 'units': '', 'date': ''},
    {'name': 'Head Circ', 'result': '0', 'units': '', 'date': ''},
    {'name': 'Waist Circ', 'result': '0', 'units': '', 'date': ''},
  ];
}
