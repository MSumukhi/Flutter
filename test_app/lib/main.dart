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

// Function to retrieve patient data
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
        for (var patient in patients) {
          print('Patient ID: ${patient['pat_id']}');
          print('First Name: ${patient['first_name']}');
          print('Last Name: ${patient['last_name']}');
          // Print other patient details as needed
          print('--------------------------------');
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

// Function to retrieve observation data
Future<void> getObservationData() async {
  if (bearerToken != null) {
    try {
      final String encodedOperation = base64Encode(utf8.encode('GET/db/observations'));

      final response = await http.get(
        Uri.parse('$apiUrl/$encodedOperation'),
        headers: {'Authorization': 'Bearer $bearerToken', 'Accept': 'application/json'},
      );

      print('Get observation data response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> observations = jsonDecode(response.body)['db'];
        for (var observation in observations) {
          print('Observation ID: ${observation['obs_id']}');
          print('Patient ID: ${observation['pat_id']}');
          print('Observation Name: ${observation['obs_name']}');
          print('Observation Result: ${observation['obs_result']}');
          print('Observer ID: ${observation['observer_id']}');
          print('Observed DateTime: ${observation['observed_datetime']}');
          print('Observation Code: ${observation['obs_code']}');
          print('Template ID: ${observation['template_id']}');
          print('Revision Number: ${observation['revision_number']}');
          print('User ID: ${observation['user_id']}');
          print('Observation Order: ${observation['obs_order']}');
          print('Observation Range: ${observation['obs_range']}');
          print('Observation Units: ${observation['obs_units']}');
          print('Observation Flag: ${observation['obs_flag']}');
          print('Observation Status: ${observation['obs_status']}');
          print('Verified DateTime: ${observation['verified_datetime']}');
          print('Restricted: ${observation['restricted']}');
          print('Create DateTime: ${observation['create_datetime']}');
          print('Modified DateTime: ${observation['modified_datetime']}');
          print('Interface: ${observation['interface']}');
          print('Observation Ext ID: ${observation['obs_ext_id']}');
          print('Test Comments: ${observation['test_comments']}');
          print('Free Text: ${observation['free_text']}');
          print('Micro Result: ${observation['micro_result']}');
          print('Interpretive Text: ${observation['interpretive_text']}');
          print('Inpatient: ${observation['inpatient']}');
          print('Observed Start TS: ${observation['observed_start_ts']}');
          print('Observed End TS: ${observation['observed_end_ts']}');
          print('--------------------------------');
        }
      } else {
        print('Failed to retrieve observation data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving observation data: $e');
    }
  } else {
    print('Bearer token not available. Cannot make request for observation data.');
  }
}

void main() async {
  // Provide your username and password here
  final String username = 'Sumu1231';
  final String password = 'Sumukhi@1231';

  await authenticateUser(username, password);
  await getPatientData();
  await getObservationData();
}
