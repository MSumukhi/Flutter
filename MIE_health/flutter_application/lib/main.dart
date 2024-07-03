import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'webchart_service.dart';  // Import the webchart_service.dart

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _steps = 0;
  double _height = 0;
  double _weight = 0;
  DateTime _healthDataTime = DateTime.now();
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _vitals = [];
  HealthFactory _health = HealthFactory();

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    await fetchSteps();
    await fetchHeightAndWeight();
    setState(() {});
  }

  Future<void> fetchSteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final health = HealthFactory();
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];

    bool requested = await health.requestAuthorization(types, permissions: permissions);
    if (requested) {
      try {
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(midnight, now, types);
        int steps = 0;

        for (var data in healthData) {
          if (data.type == HealthDataType.STEPS) {
            steps += data.value.round();
          }
        }

        setState(() {
          _steps = steps;
        });

        print('Total steps today: $_steps');
      } catch (e) {
        print('Caught exception in getHealthDataFromTypes: $e');
      }
    } else {
      print('Authorization not granted');
    }
  }

  Future<void> fetchHeightAndWeight() async {
    var types = [
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
    ];

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 365 * 2));

    bool requested = await _health.requestAuthorization(types);
    if (requested) {
      try {
        List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(startDate, now, types);

        double height = 0;
        double weight = 0;
        DateTime latestTime = DateTime.now();

        for (var data in healthData) {
          if (data.dateFrom.isAfter(latestTime)) {
            latestTime = data.dateFrom;
          }
          if (data.type == HealthDataType.HEIGHT) {
            height = data.value.toDouble();
          } else if (data.type == HealthDataType.WEIGHT) {
            weight = data.value.toDouble();
          }
        }

        setState(() {
          _height = height * 3.28084; // converting meters to feet
          _weight = weight * 2.20462; // converting kg to pounds
          _healthDataTime = latestTime;
        });

        print('Height in meters: $height');
        print('Height in feet: $_height');
        print('Weight in kg: $weight');
        print('Weight in lbs: $_weight');
      } catch (error) {
        print("Caught exception in fetchHeightAndWeight: $error");
      }
    } else {
      print("Authorization not granted - error in authorization");
    }
  }

  Future<void> showLoginDialog() async {
    String username = '';
    String password = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login to WebChart'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    username = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    password = value;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Login'),
              onPressed: () async {
                Navigator.of(context).pop();
                await fetchWebChartData(username, password);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchWebChartData(String username, String password) async {
    try {
      await authenticateUser(username, password);
      final patientData = await getPatientData();
      if (patientData == null || !patientData.containsKey('pat_id')) {
        print('No valid patient data found');
        setState(() {
          _vitals = _getDefaultVitals();
        });
        return;
      }

      print('Fetched patient data: $patientData');

      // Fetch WebChart vitals
      final webChartVitals = await getVitalsData(patientData['pat_id']);
      print('Fetched webchart vitals: $webChartVitals');

      setState(() {
        _patientData = patientData;
        _vitals = _mergeWithDefaultVitals(webChartVitals);
      });

      // Compare height and weight, prompt for update if necessary
      for (var vital in _vitals) {
        if (vital['name'] == 'Height' && (vital['result'] == '0' || DateTime.parse(vital['date']).isBefore(_healthDataTime))) {
          await promptForUpdate('Height', _height, 'ft');
        } else if (vital['name'] == 'Weight' && (vital['result'] == '0' || DateTime.parse(vital['date']).isBefore(_healthDataTime))) {
          await promptForUpdate('Weight', _weight, 'lbs');
        }
      }

      // Update WebChart with the latest Health data if not already done
      await updateWebChartWithHealthData(patientData['pat_id'], _height, _weight);

    } catch (e) {
      print('Error fetching WebChart data: $e');
      setState(() {
        _vitals = _getDefaultVitals();
      });
    }
  }

  List<Map<String, dynamic>> _mergeWithDefaultVitals(List<Map<String, dynamic>> webChartVitals) {
    final defaultVitals = _getDefaultVitals();
    final Map<String, Map<String, dynamic>> latestVitals = { for (var vital in defaultVitals) vital['name']: vital };

    for (var vital in webChartVitals) {
      if (latestVitals.containsKey(vital['name'])) {
        latestVitals[vital['name']] = vital;
      }
    }

    return latestVitals.values.toList();
  }

  Future<void> promptForUpdate(String vitalName, double value, String unit) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update WebChart'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Health data has more recent $vitalName value.'),
                Text('Would you like to update WebChart with this value?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () async {
                Navigator.of(context).pop();
                await updateWebChartWithHealthData(_patientData!['pat_id'], vitalName == 'Height' ? value : _height, vitalName == 'Weight' ? value : _weight);
                await fetchWebChartData(_patientData!['username'], _patientData!['password']);
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getDefaultVitals() {
    return [
      {'name': 'Height', 'result': '0', 'units': 'ft', 'date': '', 'loincCode': '8302-2'},
      {'name': 'Weight', 'result': '0', 'units': 'lbs', 'date': '', 'loincCode': '29463-7'},
      {'name': 'BMI', 'result': '0', 'units': '', 'date': '', 'loincCode': '39156-5'},
      {'name': 'Blood Pressure', 'result': '0/0', 'units': '', 'date': '', 'loincCode': '8480-6'},
      {'name': 'Pulse', 'result': '0', 'units': '', 'date': '', 'loincCode': '8867-4'},
      {'name': 'Temp', 'result': '0', 'units': '', 'date': '', 'loincCode': '8310-5'},
      {'name': 'Resp', 'result': '0', 'units': '', 'date': '', 'loincCode': '9279-1'},
      {'name': 'O2 Sat', 'result': '0', 'units': '', 'date': '', 'loincCode': '2708-6'},
      {'name': 'Head Circ', 'result': '0', 'units': '', 'date': '', 'loincCode': '8287-5'},
      {'name': 'Waist Circ', 'result': '0', 'units': '', 'date': '', 'loincCode': '56086-2'},
    ];
  }

  String _formatHeight(double height) {
  int feet = height.floor();
  int inches = ((height - feet) * 12).round();
  return "$feet' $inches\"";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    backgroundColor: Colors.white,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView( // Add SingleChildScrollView to handle overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Steps:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$_steps',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Height:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _formatHeight(_height),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Weight:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '${_weight.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: showLoginDialog,
                      child: Text('Access WebChart Data'),
                    ),
                  ),
                  if (_patientData != null) ...[
                    SizedBox(height: 20),
                    Text(
                      'Patient Details:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text('ID: ${_patientData!['pat_id']}'),
                    Text('First Name: ${_patientData!['first_name']}'),
                    Text('Last Name: ${_patientData!['last_name']}'),
                    Text('Email: ${_patientData!['email']}'),
                    Text('Birth Date: ${_patientData!['birth_date']}'),
                    Text('Phone: ${_patientData!['cell_phone']}'),
                  ],
                  if (_vitals.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Text(
                      'Vitals:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    for (var vital in _vitals)
                      Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']}) [LOINC Code: ${vital['loincCode']}]'),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
