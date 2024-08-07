import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'webchart_service.dart';
import 'patient_details_page.dart';
import 'profile_page.dart'; // Import ProfilePage
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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
  double _systolic = 0;
  double _diastolic = 0;
  DateTime _heightTimestamp = DateTime.now();
  DateTime _weightTimestamp = DateTime.now();
  DateTime _systolicTimestamp = DateTime.now();
  DateTime _diastolicTimestamp = DateTime.now();
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _vitals = [];
  HealthFactory _health = HealthFactory();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    fetchHealthData();
    loadUserName();
  }

  Future<void> fetchHealthData() async {
    await fetchSteps();
    await fetchHeightAndWeight();
    await fetchBloodPressure();
    setState(() {});
  }

  Future<void> loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
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

        double heightInMeters = 0;
        double weightInKg = 0;
        DateTime? heightTimestamp;
        DateTime? weightTimestamp;

        for (var data in healthData) {
          if (data.type == HealthDataType.HEIGHT && (heightTimestamp == null || data.dateFrom.isAfter(heightTimestamp))) {
            heightInMeters = data.value.toDouble();
            heightTimestamp = data.dateFrom;
          } else if (data.type == HealthDataType.WEIGHT && (weightTimestamp == null || data.dateFrom.isAfter(weightTimestamp))) {
            weightInKg = data.value.toDouble();
            weightTimestamp = data.dateFrom;
          }
        }

        setState(() {
          _height = metersToFeet(heightInMeters);
          _weight = weightInKg * 2.20462; // converting kg to pounds
          if (heightTimestamp != null) _heightTimestamp = heightTimestamp;
          if (weightTimestamp != null) _weightTimestamp = weightTimestamp;
        });

        print('Height retrieved from Health app in meters: $heightInMeters');
        print('Height retrieved from Health app in feet: $_height');
        print('Height timestamp: $_heightTimestamp');
        print('Weight in kg: $weightInKg');
        print('Weight in lbs: $_weight');
        print('Weight timestamp: $_weightTimestamp');
      } catch (error) {
        print("Caught exception in fetchHeightAndWeight: $error");
      }
    } else {
      print("Authorization not granted - error in authorization");
    }
  }

  Future<void> fetchBloodPressure() async {
    var types = [
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    ];

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 365 * 2));

    bool requested = await _health.requestAuthorization(types);
    if (requested) {
      try {
        List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(startDate, now, types);

        double systolic = 0;
        double diastolic = 0;
        DateTime? systolicTimestamp;
        DateTime? diastolicTimestamp;

        for (var data in healthData) {
          if (data.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC && (systolicTimestamp == null || data.dateFrom.isAfter(systolicTimestamp))) {
            systolic = data.value.toDouble();
            systolicTimestamp = data.dateFrom;
          } else if (data.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC && (diastolicTimestamp == null || data.dateFrom.isAfter(diastolicTimestamp))) {
            diastolic = data.value.toDouble();
            diastolicTimestamp = data.dateFrom;
          }
        }

        setState(() {
          _systolic = systolic;
          _diastolic = diastolic;
          if (systolicTimestamp != null) _systolicTimestamp = systolicTimestamp;
          if (diastolicTimestamp != null) _diastolicTimestamp = diastolicTimestamp;
        });

        print('Systolic: $systolic');
        print('Systolic timestamp: $_systolicTimestamp');
        print('Diastolic: $diastolic');
        print('Diastolic timestamp: $_diastolicTimestamp');
      } catch (error) {
        print("Caught exception in fetchBloodPressure: $error");
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
                    icon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    password = value;
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    icon: Icon(Icons.lock),
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
            ElevatedButton(
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
              vitals: _vitals,
              healthHeight: _height,
              healthWeight: _weight,
              healthSystolic: _systolic,
              healthDiastolic: _diastolic,
              heightTimestamp: _heightTimestamp,
              weightTimestamp: _weightTimestamp,
              systolicTimestamp: _systolicTimestamp,
              diastolicTimestamp: _diastolicTimestamp,
            ),
          ),
        );
      });
    }
  }

  Future<void> fetchWebChartData(String username, String password) async {
    try {
      await authenticateUser(username, password);

      // Provide the patient ID directly
      final String patientId = '111'; // Replace with the actual patient ID or obtain it dynamically

      final patientData = await getPatientData(patientId);
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
        _vitals = webChartVitals.isNotEmpty ? webChartVitals : _getDefaultVitals();
      });

      print('Height retrieved from WebChart: ${_vitals.firstWhere((vital) => vital['loinc_num'] == '8302-2', orElse: () => {'result': '0'})['result']} ft');
    } catch (e) {
      print('Error fetching WebChart data: $e');
      setState(() {
        _vitals = _getDefaultVitals();
      });
    }
  }

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

  String _formatHeight(double height) {
    int feet = height.floor();
    int inches = ((height - feet) * 12).round();
    return "$feet' $inches\"";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()), // Navigate to ProfilePage
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchHealthData,
          ),
        ],
      ),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_userName!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    ListTile(
                      leading: Icon(Icons.directions_walk),
                      title: Text('Total Steps:'),
                      subtitle: Text('$_steps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: Icon(Icons.height),
                      title: Text('Height:'),
                      subtitle: Text(_formatHeight(_height), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      leading: Icon(Icons.fitness_center),
                      title: Text('Weight:'),
                      subtitle: Text('${_weight.toStringAsFixed(1)} lbs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

double metersToFeet(double meters) {
  return meters * 3.28084; // Converts meters to feet
}