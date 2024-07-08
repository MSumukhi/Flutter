import 'package:flutter/material.dart';
import 'webchart_service.dart'; // Import the webchart_service.dart

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;
  final double healthHeight;
  final double healthWeight;

  const PatientDetailsPage({
    super.key,
    required this.patientData,
    required this.vitals,
    required this.healthHeight,
    required this.healthWeight,
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
    double webChartHeight = double.parse(widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['result']);
    double webChartWeight = double.parse(widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['result']);
    DateTime? webChartHeightTime;
    DateTime? webChartWeightTime;

    String heightDateStr = widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['date'];
    String weightDateStr = widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['date'];

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

    if (widget.healthHeight != webChartHeight || widget.healthWeight != webChartWeight) {
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
      });
    }
  }

  Future<void> _updateVitals() async {
    await updateWebChartWithHealthData(widget.patientData['pat_id'], widget.healthHeight, widget.healthWeight);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart updated successfully.')));

    // Update the vitals to reflect the changes
    setState(() {
      widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['result'] = widget.healthHeight.toString();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['result'] = widget.healthWeight.toString();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['date'] = DateTime.now().toIso8601String();
      widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['date'] = DateTime.now().toIso8601String();
      _showUpdateButton = false;
      _updateMessage = '';
    });
  }

  void _viewAndCopyWebChartData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAndCopyDataPage(
          patientData: widget.patientData,
          vitals: widget.vitals,
        ),
      ),
    );
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
              ],
            ),
            Center(
              child: ElevatedButton(
                onPressed: _viewAndCopyWebChartData,
                child: Text('View and Copy WebChart Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewAndCopyDataPage extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;

  const ViewAndCopyDataPage({super.key, required this.patientData, required this.vitals});

  Future<void> _copyWebChartData(BuildContext context) async {
    await savePatientData(patientData);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart data copied to local storage.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View and Copy WebChart Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ExpansionTile(
              title: Text('Patient Details'),
              children: [
                ListTile(title: Text('ID: ${patientData['pat_id']}')),
                ListTile(title: Text('First Name: ${patientData['first_name']}')),
                ListTile(title: Text('Last Name: ${patientData['last_name']}')),
                ListTile(title: Text('Email: ${patientData['email']}')),
                ListTile(title: Text('Birth Date: ${patientData['birth_date']}')),
                ListTile(title: Text('Phone: ${patientData['cell_phone']}')),
              ],
            ),
            ExpansionTile(
              title: Text('Vitals'),
              children: [
                ...vitals.map((vital) {
                  return ListTile(
                    title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
                  );
                }).toList(),
              ],
            ),
            Center(
              child: ElevatedButton(
                onPressed: () => _copyWebChartData(context),
                child: Text('Copy WebChart Data to Local Storage'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
