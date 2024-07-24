import 'package:flutter/material.dart';
import 'webchart_service.dart';
import 'fhir_patient_page.dart';
import 'update_health_service.dart';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;
  double healthHeight;
  double healthWeight;
  final double healthSystolic;
  final double healthDiastolic;
  DateTime heightTimestamp;
  DateTime weightTimestamp;
  final DateTime systolicTimestamp;
  final DateTime diastolicTimestamp;

  PatientDetailsPage({
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
  bool _showHealthUpdateButton = false;
  String _updateMessage = '';

  @override
  void initState() {
    super.initState();
    _compareVitals();
  }

  void _compareVitals() {
    DateTime? webChartHeightTime = _getVitalTimestamp('8302-2');
    DateTime? webChartWeightTime = _getVitalTimestamp('29463-7');

    print('Comparing WebChart and Health app data:');
    print('WebChart Height Timestamp: $webChartHeightTime');
    print('Health App Height Timestamp: ${widget.heightTimestamp}');
    print('WebChart Weight Timestamp: $webChartWeightTime');
    print('Health App Weight Timestamp: ${widget.weightTimestamp}');

    bool shouldUpdateWebChartHeight = false;
    bool shouldUpdateHealthHeight = false;
    bool shouldUpdateWebChartWeight = false;
    bool shouldUpdateHealthWeight = false;

    if (webChartHeightTime != null && webChartHeightTime.isAfter(widget.heightTimestamp)) {
      shouldUpdateHealthHeight = true;
    }

    if (widget.heightTimestamp.isAfter(webChartHeightTime ?? DateTime(0))) {
      shouldUpdateWebChartHeight = true;
    }

    if (webChartWeightTime != null && webChartWeightTime.isAfter(widget.weightTimestamp)) {
      shouldUpdateHealthWeight = true;
    }

    if (widget.weightTimestamp.isAfter(webChartWeightTime ?? DateTime(0))) {
      shouldUpdateWebChartWeight = true;
    }

    if (shouldUpdateWebChartHeight || shouldUpdateHealthHeight || shouldUpdateWebChartWeight || shouldUpdateHealthWeight) {
      setState(() {
        _updateMessage = '';
        if (shouldUpdateHealthHeight) {
          _updateMessage += 'There is a more recent height value in WebChart data.\n';
        } else if (shouldUpdateWebChartHeight) {
          _updateMessage += 'There is a more recent height value in Health data.\n';
        }
        if (shouldUpdateHealthWeight) {
          _updateMessage += 'There is a more recent weight value in WebChart data.\n';
        } else if (shouldUpdateWebChartWeight) {
          _updateMessage += 'There is a more recent weight value in Health data.\n';
        }
      });
    } else {
      setState(() {
        _updateMessage = '';
      });
    }

    setState(() {
      _showUpdateButton = shouldUpdateWebChartHeight || shouldUpdateWebChartWeight;
      _showHealthUpdateButton = shouldUpdateHealthHeight || shouldUpdateHealthWeight;
    });
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

    setState(() {
      try {
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8302-2')['result'] = widget.healthHeight.toString();
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '29463-7')['result'] = widget.healthWeight.toString();
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8302-2')['date'] = widget.heightTimestamp.toIso8601String();
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '29463-7')['date'] = widget.weightTimestamp.toIso8601String();
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8480-6')['result'] = widget.healthSystolic.toStringAsFixed(2);
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8462-4')['result'] = widget.healthDiastolic.toStringAsFixed(2);
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8480-6')['date'] = widget.systolicTimestamp.toIso8601String();
        widget.vitals.firstWhere((vital) => vital['loinc_num'] == '8462-4')['date'] = widget.diastolicTimestamp.toIso8601String();
      } catch (e) {
        print('Error updating vitals: $e');
      }
      _showUpdateButton = false;
      _updateMessage = '';
    });
  }

  Future<void> _updateHealthHeight() async {
    DateTime? webChartHeightTime = _getVitalTimestamp('8302-2');

    if (webChartHeightTime != null && webChartHeightTime.isAfter(widget.heightTimestamp)) {
      widget.healthHeight = _getVitalResult('8302-2', widget.healthHeight);
      widget.heightTimestamp = webChartHeightTime;
    }

    bool success = await updateHealthHeight(
      widget.healthHeight,
      widget.heightTimestamp,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health data updated successfully.')));
      setState(() {
        _showHealthUpdateButton = false;
      });
    }
  }

  Future<void> _updateHealthWeight() async {
    DateTime? webChartWeightTime = _getVitalTimestamp('29463-7');

    if (webChartWeightTime != null && webChartWeightTime.isAfter(widget.weightTimestamp)) {
      widget.healthWeight = _getVitalResult('29463-7', widget.healthWeight);
      widget.weightTimestamp = webChartWeightTime;
    }

    bool success = await updateHealthWeight(
      widget.healthWeight,
      widget.weightTimestamp,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Health data updated successfully.')));
      setState(() {
        _showHealthUpdateButton = false;
      });
    }
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
                if (_showUpdateButton || _showHealthUpdateButton) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _updateMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  if (_showUpdateButton)
                    ElevatedButton(
                      onPressed: _updateVitals,
                      child: Text('Update WebChart with Health Data'),
                    ),
                  if (_showHealthUpdateButton) ...[
                    ElevatedButton(
                      onPressed: _updateHealthHeight,
                      child: Text('Update Health Height with WebChart Data'),
                    ),
                    ElevatedButton(
                      onPressed: _updateHealthWeight,
                      child: Text('Update Health Weight with WebChart Data'),
                    ),
                  ],
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
