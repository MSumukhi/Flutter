import 'package:flutter/material.dart';
import 'webchart_service.dart'; // Import the webchart_service.dart
import 'fhir_patient_page.dart'; // Import the FhirPatientPage

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;
  final double healthHeight;
  final double healthWeight;
  final double healthSystolic;
  final double healthDiastolic;
  final DateTime heightTimestamp;
  final DateTime weightTimestamp;
  final DateTime systolicTimestamp;
  final DateTime diastolicTimestamp;

  const PatientDetailsPage({
    super.key,
    required this.patientData,
    required this.vitals,
    required this.healthHeight,
    required this.healthWeight,
    required this.healthSystolic,
    required this.healthDiastolic,
    required this.heightTimestamp,
    required this.weightTimestamp,
    required this.systolicTimestamp,
    required this.diastolicTimestamp,
  });

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  bool _showUpdateButton = false;
  String _updateMessage = '';

  @override
  void initState() {
    super.initState();
    _compareVitals();
  }

  void _compareVitals() {
    double webChartHeight = _getVitalResult('8302-2', 0.0); // Height LOINC code
    double webChartWeight = _getVitalResult('29463-7', 0.0); // Weight LOINC code
    double webChartSystolic = _getVitalResult('8480-6', 0.0); // Systolic BP LOINC code
    double webChartDiastolic = _getVitalResult('8462-4', 0.0); // Diastolic BP LOINC code
    DateTime? webChartHeightTime = _getVitalTimestamp('8302-2'); // Height LOINC code
    DateTime? webChartWeightTime = _getVitalTimestamp('29463-7'); // Weight LOINC code
    DateTime? webChartSystolicTime = _getVitalTimestamp('8480-6'); // Systolic BP LOINC code
    DateTime? webChartDiastolicTime = _getVitalTimestamp('8462-4'); // Diastolic BP LOINC code

    // Debug statements to check values and timestamps
    print('Comparing Vitals:');
    print('Health Height: ${widget.healthHeight}, WebChart Height: $webChartHeight');
    print('Health Weight: ${widget.healthWeight}, WebChart Weight: $webChartWeight');
    print('Health Systolic: ${widget.healthSystolic}, WebChart Systolic: $webChartSystolic');
    print('Health Diastolic: ${widget.healthDiastolic}, WebChart Diastolic: $webChartDiastolic');
    print('Health Systolic Timestamp: ${widget.systolicTimestamp}, WebChart Systolic Timestamp: $webChartSystolicTime');
    print('Health Diastolic Timestamp: ${widget.diastolicTimestamp}, WebChart Diastolic Timestamp: $webChartDiastolicTime');

    if (widget.healthHeight != webChartHeight || widget.healthWeight != webChartWeight || widget.healthSystolic != webChartSystolic || widget.healthDiastolic != webChartDiastolic) {
      setState(() {
        _showUpdateButton = true;
        if (widget.healthHeight != webChartHeight) {
          if (webChartHeightTime == null || webChartHeightTime.isBefore(widget.heightTimestamp)) {
            _updateMessage += 'There is a more recent height value from Health data.\n';
          }
        }
        if (widget.healthWeight != webChartWeight) {
          if (webChartWeightTime == null || webChartWeightTime.isBefore(widget.weightTimestamp)) {
            _updateMessage += 'There is a more recent weight value from Health data.\n';
          }
        }
        if (widget.healthSystolic != webChartSystolic || widget.healthDiastolic != webChartDiastolic) {
          if (webChartSystolicTime == null || webChartSystolicTime.isBefore(widget.systolicTimestamp) || webChartDiastolicTime == null || webChartDiastolicTime.isBefore(widget.diastolicTimestamp)) {
            _updateMessage += 'There is a more recent blood pressure value from Health data.\n';
          }
        }
      });
    }
  }

  double _getVitalResult(String loincCode, double defaultValue) {
    try {
      var vital = widget.vitals.firstWhere(
          (vital) => vital['loinc_num'] == loincCode,
          orElse: () {
            print('Vital with LOINC code $loincCode not found, returning default value $defaultValue');
            return {'result': defaultValue.toString()};
          });
      return double.parse(vital['result']);
    } catch (e) {
      print('Error getting $loincCode result: $e');
      return defaultValue;
    }
  }

  DateTime? _getVitalTimestamp(String loincCode) {
    try {
      var vital = widget.vitals.firstWhere(
          (vital) => vital['loinc_num'] == loincCode,
          orElse: () {
            print('Vital with LOINC code $loincCode not found, returning empty date');
            return {'date': ''};
          });
      return vital['date'].isNotEmpty ? DateTime.parse(vital['date']) : null;
    } catch (e) {
      print('Error getting $loincCode date: $e');
      return null;
    }
  }

  Future<void> _updateVitals() async {
    await updateWebChartWithHealthData(
      widget.patientData['pat_id'],
      widget.healthHeight,
      widget.healthWeight,
      widget.healthSystolic,
      widget.healthDiastolic,
      widget.heightTimestamp,
      widget.weightTimestamp,
      widget.systolicTimestamp,
      widget.diastolicTimestamp,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart updated successfully.')));

    // Update the vitals to reflect the changes
    setState(() {
      try {
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8302-2')['result'] = widget.healthHeight.toString(); // Height LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '29463-7')['result'] = widget.healthWeight.toString(); // Weight LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8302-2')['date'] = widget.heightTimestamp.toIso8601String(); // Height LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '29463-7')['date'] = widget.weightTimestamp.toIso8601String(); // Weight LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8480-6')['result'] = widget.healthSystolic.toStringAsFixed(2); // Systolic BP LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8462-4')['result'] = widget.healthDiastolic.toStringAsFixed(2); // Diastolic BP LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8480-6')['date'] = widget.systolicTimestamp.toIso8601String(); // Systolic BP LOINC code
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8462-4')['date'] = widget.diastolicTimestamp.toIso8601String(); // Diastolic BP LOINC code
      } catch (e) {
        print('Error updating vitals: $e');
      }
      _showUpdateButton = false;
      _updateMessage = '';
    });
  }

  Future<void> _fetchAndDisplayFhirPatientVitals() async {
    final fhirVitals = await getFhirPatientVitals(widget.patientData['pat_id']);
    if (fhirVitals != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FhirPatientPage(fhirData: fhirVitals),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Details and Vitals'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ExpansionTile(
              leading: Icon(Icons.person),
              title: Text('Patient Details'),
              children: [
                ListTile(title: Text('ID: ${widget.patientData['pat_id']}')),
                ListTile(title: Text('First Name: ${widget.patientData['first_name']}')),
                ListTile(title: Text('Last Name: ${widget.patientData['last_name']}')),
                ListTile(title: Text('Email: ${widget.patientData['email']}')),
                ListTile(title: Text('Birth Date: ${widget.patientData['birth_date']}')),
                ListTile(title: Text('Phone: ${widget.patientData['cell_phone']}')),
                ElevatedButton(
                  onPressed: () async {
                    final fhirData = await getFhirPatientResource(widget.patientData['pat_id']);
                    if (fhirData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FhirPatientPage(fhirData: fhirData),
                        ),
                      );
                    }
                  },
                  child: Text('Fetch FHIR Patient Resource'),
                ),
              ],
            ),
            ExpansionTile(
              leading: Icon(Icons.favorite),
              title: Text('Vitals'),
              children: [
                ...widget.vitals.map((vital) {
                  final isBloodPressure = vital['name'] == 'Blood Pressure';
                  final result = isBloodPressure
                      ? '${widget.healthSystolic.toStringAsFixed(2)} / ${widget.healthDiastolic.toStringAsFixed(2)}'
                      : vital['result'];
                  final timestamp = isBloodPressure
                      ? widget.systolicTimestamp.toIso8601String()
                      : vital['date'];
                  return ListTile(
                    title: Text(
                      '${vital['name']}: $result ${vital['units']} (${timestamp})',
                    ),
                  );
                }).toList(),
                if (_showUpdateButton) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _updateMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _updateVitals,
                    child: Text('Update WebChart with Health Data'),
                  ),
                ],
                ElevatedButton(
                  onPressed: _fetchAndDisplayFhirPatientVitals,
                  child: Text('Fetch FHIR Patient Vitals Resource'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
