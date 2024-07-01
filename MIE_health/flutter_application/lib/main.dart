import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HealthDataScreen(),
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  int totalSteps = 0;
  double height = 0.0;
  double weight = 0.0;

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
          totalSteps = steps;
        });

        print('Total steps today: $totalSteps');
      } catch (e) {
        print('Caught exception in getHealthDataFromTypes: $e');
      }
    } else {
      print('Authorization not granted');
    }
  }

  Future<void> fetchHeightAndWeight() async {
    final health = HealthFactory();
    final types = [HealthDataType.HEIGHT, HealthDataType.WEIGHT];
    final permissions = [HealthDataAccess.READ, HealthDataAccess.READ];

    bool requested = await health.requestAuthorization(types, permissions: permissions);
    if (requested) {
      try {
        final now = DateTime.now();
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

        print('Fetching health data from $oneYearAgo to $now for types $types');
        
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(oneYearAgo, now, types);

        double tempHeight = 0.0;
        double tempWeight = 0.0;

        for (var data in healthData) {
          print('Data point: ${data.type} - ${data.value}');
          if (data.type == HealthDataType.HEIGHT) {
            tempHeight = data.value.toDouble();  // Casting to double
            print('Fetched height: $tempHeight meters');
          } else if (data.type == HealthDataType.WEIGHT) {
            tempWeight = data.value.toDouble();  // Casting to double
            print('Fetched weight: $tempWeight kg');
          }
        }

        setState(() {
          height = tempHeight;
          weight = tempWeight;
        });

        print('Height in meters: $height');
        print('Weight in kg: $weight');
      } catch (e) {
        print('Caught exception in getHealthDataFromTypes: $e');
      }
    } else {
      print('Authorization not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Total steps today: $totalSteps'),
            Text('Height in meters: $height'),
            Text('Weight in kg: $weight'),
          ],
        ),
      ),
    );
  }
}
