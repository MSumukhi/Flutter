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

// Function to retrieve observation data with filter for vitals
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
          // Filtering for vitals-related observation names
          if (['Height', 'Weight', 'BMI', 'Blood Pressure', 'Pulse', 'Temp', 'Resp', 'O2 Sat'].contains(observation['obs_name'])) {
            print('Observation ID: ${observation['obs_id']}');
            print('Patient ID: ${observation['pat_id']}');
            print('Observation Name: ${observation['obs_name']}');
            print('Observation Result: ${observation['obs_result']}');
            print('Observed DateTime: ${observation['observed_datetime']}');
            print('Observation Units: ${observation['obs_units']}');
            print('--------------------------------');
          }
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
  await getObservationData();
}
