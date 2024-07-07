import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'webchart_service.dart';
import 'patient_details_page.dart';

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
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _vitalsByName = [];
  List<Map<String, dynamic>> _vitalsByLOINC = [];
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

        for (var data in healthData) {
          if (data.type == HealthDataType.HEIGHT) {
            height = data.value.toDouble();
          } else if (data.type == HealthDataType.WEIGHT) {
            weight = data.value.toDouble();
          }
        }

        setState(() {
          _height = height * 3.28084; // converting meters to feet
          _weight = weight * 2.20462; // converting kg to pounds
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
                navigateToPatientDetailsPage();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToPatientDetailsPage() {
    if (_patientData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientDetailsPage(
              patientData: _patientData!,
              vitalsByName: _vitalsByName,
              vitalsByLOINC: _vitalsByLOINC,
              healthHeight: _height,
              healthWeight: _weight,
            ),
          ),
        );
      });
    }
  }

  Future<void> fetchWebChartData(String username, String password) async {
    try {
      await authenticateUser(username, password);
      final patientData = await getPatientData();
      if (patientData == null || !patientData.containsKey('pat_id')) {
        print('No valid patient data found');
        setState(() {
          _vitalsByName = _getDefaultVitals();
          _vitalsByLOINC = _getDefaultVitals();
        });
        return;
      }

      print('Fetched patient data: $patientData');

      final webChartVitalsByName = await getVitalsDataByName(patientData['pat_id']);
      final webChartVitalsByLOINC = await getVitalsDataByLOINC(patientData['pat_id']);
      print('Fetched webchart vitals by name: $webChartVitalsByName');
      print('Fetched webchart vitals by LOINC: $webChartVitalsByLOINC');

      setState(() {
        _patientData = patientData;
        _vitalsByName = webChartVitalsByName.isNotEmpty ? webChartVitalsByName : _getDefaultVitals();
        _vitalsByLOINC = webChartVitalsByLOINC.isNotEmpty ? webChartVitalsByLOINC : _getDefaultVitals();
      });
    } catch (e) {
      print('Error fetching WebChart data: $e');
      setState(() {
        _vitalsByName = _getDefaultVitals();
        _vitalsByLOINC = _getDefaultVitals();
      });
    }
  }

  List<Map<String, dynamic>> _getDefaultVitals() {
    return [
      {'name': 'Height', 'result': '0', 'units': 'ft', 'date': ''},
      {'name': 'Weight', 'result': '0', 'units': 'lbs', 'date': ''},
      {'name': 'BMI', 'result': '0', 'units': '', 'date': ''},
      {'name': 'Blood Pressure', 'result': '0/0', 'units': '', 'date': ''},
      {'name': 'Pulse', 'result': '0', 'units': '', 'date': ''},
      {'name': 'Temp', 'result': '0', 'units': '', 'date': ''},
      {'name': 'Resp', 'result': '0', 'units': '', 'date': ''},
      {'name': 'O2 Sat', 'result': '0', 'units': '', 'date': ''},
      {'name': 'Head Circ', 'result': '0', 'units': '', 'date': ''},
      {'name': 'Waist Circ', 'result': '0', 'units': '', 'date': ''},
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
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
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
