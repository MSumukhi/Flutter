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

  const PatientDetailsPage({
    super.key,
    required this.patientData,
    required this.vitals,
    required this.healthHeight,
    required this.healthWeight,
    required this.healthSystolic,
    required this.healthDiastolic,
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
    double webChartHeight = _getVitalResult('Height', 0.0);
    double webChartWeight = _getVitalResult('Weight', 0.0);
    double webChartSystolic = _getVitalResult('Blood Pressure', 0.0, isSystolic: true);
    double webChartDiastolic = _getVitalResult('Blood Pressure', 0.0, isSystolic: false);
    DateTime? webChartHeightTime;
    DateTime? webChartWeightTime;
    DateTime? webChartSystolicTime;
    DateTime? webChartDiastolicTime;

    String heightDateStr = _getVitalDate('Height');
    String weightDateStr = _getVitalDate('Weight');
    String systolicDateStr = _getVitalDate('Blood Pressure', isSystolic: true);
    String diastolicDateStr = _getVitalDate('Blood Pressure', isSystolic: false);

    try {
      webChartHeightTime = heightDateStr.isNotEmpty ? DateTime.parse(heightDateStr) : null;
    } catch (e) {
      print('Error parsing height date: $e');
    }

    try {
      webChartWeightTime = weightDateStr.isNotEmpty ? DateTime.parse(weightDateStr) : null;
    } catch (e) {
      print('Error parsing weight date: $e');
    }

    try {
      webChartSystolicTime = systolicDateStr.isNotEmpty ? DateTime.parse(systolicDateStr) : null;
    } catch (e) {
      print('Error parsing systolic date: $e');
    }

    try {
      webChartDiastolicTime = diastolicDateStr.isNotEmpty ? DateTime.parse(diastolicDateStr) : null;
    } catch (e) {
      print('Error parsing diastolic date: $e');
    }

    if (widget.healthHeight != webChartHeight || widget.healthWeight != webChartWeight || widget.healthSystolic != webChartSystolic || widget.healthDiastolic != webChartDiastolic) {
      setState(() {
        _showUpdateButton = true;
        if (widget.healthHeight != webChartHeight) {
          if (webChartHeightTime == null || webChartHeightTime.isBefore(DateTime.now())) {
            _updateMessage += 'There is a more recent height value from Health data.\n';
          }
        }
        if (widget.healthWeight != webChartWeight) {
          if (webChartWeightTime == null || webChartWeightTime.isBefore(DateTime.now())) {
            _updateMessage += 'There is a more recent weight value from Health data.\n';
          }
        }
        if (widget.healthSystolic != webChartSystolic || widget.healthDiastolic != webChartDiastolic) {
          if (webChartSystolicTime == null || webChartSystolicTime.isBefore(DateTime.now()) || webChartDiastolicTime == null || webChartDiastolicTime.isBefore(DateTime.now())) {
            _updateMessage += 'There is a more recent blood pressure value from Health data.\n';
          }
        }
      });
    }
  }

  double _getVitalResult(String name, double defaultValue, {bool isSystolic = true}) {
    try {
      var vital = widget.vitals.firstWhere((vital) => vital['name'] == name);
      if (name == 'Blood Pressure') {
        return isSystolic
            ? double.parse(vital['result'].split('/')[0])
            : double.parse(vital['result'].split('/')[1]);
      }
      return double.parse(vital['result']);
    } catch (e) {
      print('Error getting $name result: $e');
      return defaultValue;
    }
  }

  String _getVitalDate(String name, {bool isSystolic = true}) {
    try {
      var vital = widget.vitals.firstWhere((vital) => vital['name'] == name);
      return vital['date'];
    } catch (e) {
      print('Error getting $name date: $e');
      return '';
    }
  }

  Future<void> _updateVitals() async {
    await updateWebChartWithHealthData(widget.patientData['pat_id'], widget.healthHeight, widget.healthWeight, widget.healthSystolic, widget.healthDiastolic);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart updated successfully.')));

    // Update the vitals to reflect the changes
    setState(() {
      widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['result'] = widget.healthHeight.toString();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['result'] = widget.healthWeight.toString();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['date'] = DateTime.now().toIso8601String();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['date'] = DateTime.now().toIso8601String();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Blood Pressure')['result'] = '${widget.healthSystolic}/${widget.healthDiastolic}';
      widget.vitals.firstWhere((vital) => vital['name'] == 'Blood Pressure')['date'] = DateTime.now().toIso8601String();
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ExpansionTile(
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
              title: Text('Vitals'),
              children: [
                ...widget.vitals.map((vital) {
                  return ListTile(
                    title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
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
