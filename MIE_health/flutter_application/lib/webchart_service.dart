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
Future<Map<String, dynamic>?> getPatientData(String patientId) async {
  if (bearerToken != null) {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/R0VUL2RiL3BhdGllbnRz'), // Base64 encoded URL for GET/db/patients
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'options': {
            'pat_id': patientId
          }
        }),
      );
      print('Get patient data response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> patients = jsonDecode(response.body)['db'];
        if (patients.isNotEmpty) {
          return patients.first;
        } else {
          print('Patient with ID $patientId not found');
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
          'loinc_code': '8302-2', // Height LOINC code
          'obs_result': height.toStringAsFixed(2),
          'obs_units': 'ft',
          'observed_datetime': heightTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'loinc_code': '29463-7', // Weight LOINC code
          'obs_result': weight.toStringAsFixed(2),
          'obs_units': 'lbs',
          'observed_datetime': weightTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'loinc_code': '8480-6', // Systolic BP LOINC code
          'obs_result': systolic.toStringAsFixed(2),
          'obs_units': 'mmHg',
          'observed_datetime': systolicTimestamp.toIso8601String()
        },
        {
          'pat_id': patientId,
          'loinc_code': '8462-4', // Diastolic BP LOINC code
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

// Function to retrieve latest vitals data for a specific patient
Future<List<Map<String, dynamic>>> getVitalsData(String patientId) async {
  if (bearerToken != null) {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/R0VUL2RiL29ic2VydmF0aW9ucw=='), // Base64 encoded URL
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'options': {
            'pat_id': patientId
          }
        }),
      );
      print('Get vitals data response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> observations = jsonDecode(response.body)['db'];

        // Filter and map observations to vitals
        final List<Map<String, dynamic>> vitals = observations
            .where((obs) => observationNameMapping.containsKey(obs['obs_name']))
            .map((obs) => {
                  'loinc_code': observationNameMapping[obs['obs_name']],
                  'name': observationLoincMapping[observationNameMapping[obs['obs_name']]],
                  'result': obs['obs_result'],
                  'date': obs['observed_datetime'],
                  'units': obs['obs_units'] ?? ''
                })
            .toList();

        // Ensure all vitals are present, set to zero if not found
        final Map<String, Map<String, dynamic>> latestVitals = {};
        for (var vital in vitals) {
          if (!latestVitals.containsKey(vital['loinc_code']) || DateTime.parse(latestVitals[vital['loinc_code']]!['date']).isBefore(DateTime.parse(vital['date']))) {
            latestVitals[vital['loinc_code']] = vital;
          }
        }
        final allVitals = _getDefaultVitals().map((defaultVital) {
          return latestVitals[defaultVital['loinc_code']] ?? defaultVital;
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

// Mapping of observation names to LOINC codes
const Map<String, String> observationNameMapping = {
  'BODY HEIGHT': '8302-2',
  'BODY WEIGHT': '29463-7',
  'BMI': '39156-5',
  'Systolic BP': '8480-6',
  'Diastolic BP': '8462-4',
  'Pulse': '8867-4',
  'BODY TEMPERATURE': '8310-5',
  'RESPIRATION RATE': '9279-1',
  'O2 Sat': '2708-6',
  'Head Circ': '8287-5',
  'Waist Circ': '56115-9'
};

// Mapping of LOINC codes to the expected vital names
const Map<String, String> observationLoincMapping = {
  '8302-2': 'Height',
  '29463-7': 'Weight',
  '39156-5': 'BMI',
  '8480-6/8462-4': 'Blood Pressure',
  '8867-4': 'Pulse',
  '8310-5': 'Temp',
  '9279-1': 'Resp',
  '2708-6': 'O2 Sat',
  '8287-5': 'Head Circ',
  '56115-9': 'Waist Circ'
};

List<Map<String, dynamic>> _getDefaultVitals() {
  return [
    {'loinc_code': '8302-2', 'name': 'Height', 'result': '0', 'units': 'ft', 'date': ''},
    {'loinc_code': '29463-7', 'name': 'Weight', 'result': '0', 'units': 'lbs', 'date': ''},
    {'loinc_code': '39156-5', 'name': 'BMI', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '8480-6/8462-4', 'name': 'Blood Pressure', 'result': '0/0', 'units': 'mmHg', 'date': ''},
    {'loinc_code': '8867-4', 'name': 'Pulse', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '8310-5', 'name': 'Temp', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '9279-1', 'name': 'Resp', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '2708-6', 'name': 'O2 Sat', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '8287-5', 'name': 'Head Circ', 'result': '0', 'units': '', 'date': ''},
    {'loinc_code': '56115-9', 'name': 'Waist Circ', 'result': '0', 'units': '', 'date': ''},
  ];
}
