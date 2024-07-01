import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _steps = 0;
  double _height = 0;
  double _weight = 0;
  HealthFactory _health = HealthFactory();

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    var types = [
      HealthDataType.STEPS,
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
    ];

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 7)); // Adjust the duration as needed

    bool requested = await _health.requestAuthorization(types);
    if (requested) {
      try {
        // Fetch steps
        int? steps = await _health.getTotalStepsInInterval(now.subtract(Duration(days: 1)), now);
        print('Steps fetched: $steps');

        // Fetch height and weight
        List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
          startDate,
          now,
          types,
        );

        double height = 0;
        double weight = 0;

        for (var data in healthData) {
          print('Health data point: ${data.type} - ${data.value} at ${data.dateFrom}');
          if (data.type == HealthDataType.HEIGHT && data.value is num) {
            height = (data.value as num).toDouble();
          } else if (data.type == HealthDataType.WEIGHT && data.value is num) {
            weight = (data.value as num).toDouble();
          }
        }

        setState(() {
          _steps = steps ?? 0;
          _height = height * 3.28084; // converting meters to feet
          _weight = weight * 2.20462; // converting kg to pounds
        });

        print('Total number of steps: $_steps');
        print('Height in meters: $height');
        print('Height in feet: $_height');
        print('Weight in kg: $weight');
        print('Weight in lbs: $_weight');
      } catch (error) {
        print("Caught exception in fetchHealthData: $error");
      }
    } else {
      print("Authorization not granted - error in authorization");
    }
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
            ],
          ),
        ),
      ),
    );
  }
}
