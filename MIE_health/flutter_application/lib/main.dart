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
  double heightInFeet = 0.0;
  double weightInLbs = 0.0;

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
        final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);

        print('Fetching health data from $twoYearsAgo to $now for types $types');
        
        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(twoYearsAgo, now, types);

        double heightInMeters = 0.0;
        double weightInKg = 0.0;

        for (var data in healthData) {
          if (data.type == HealthDataType.HEIGHT) {
            heightInMeters = data.value.toDouble();
          } else if (data.type == HealthDataType.WEIGHT) {
            weightInKg = data.value.toDouble();
          }
        }

        setState(() {
          heightInFeet = heightInMeters * 3.28084;
          weightInLbs = weightInKg * 2.20462;
        });

        print('Height in feet: $heightInFeet');
        print('Weight in lbs: $weightInLbs');
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
            Text('Height in feet: ${heightInFeet.toStringAsFixed(2)}'),
            Text('Weight in lbs: ${weightInLbs.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
