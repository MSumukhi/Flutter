import 'package:flutter/material.dart';
import 'webchart_service.dart';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitalsByName;
  final List<Map<String, dynamic>> vitalsByLOINC;
  final double healthHeight;
  final double healthWeight;

  const PatientDetailsPage({
    super.key,
    required this.patientData,
    required this.vitalsByName,
    required this.vitalsByLOINC,
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
    _printVitals();
  }

  void _printVitals() {
    print('Vitals by name: ${widget.vitalsByName}');
    print('Vitals by LOINC: ${widget.vitalsByLOINC}');
  }

  Future<void> _updateVitals() async {
    await updateWebChartWithHealthData(widget.patientData['pat_id'], widget.healthHeight, widget.healthWeight);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart updated successfully.')));

    setState(() {
      widget.vitalsByName.firstWhere((vital) => vital['name'] == 'Height')['result'] = widget.healthHeight.toString();
      widget.vitalsByName.firstWhere((vital) => vital['name'] == 'Weight')['result'] = widget.healthWeight.toString();
      widget.vitalsByName.firstWhere((vital) => vital['name'] == 'Height')['date'] = DateTime.now().toIso8601String();
      widget.vitalsByName.firstWhere((vital) => vital['name'] == 'Weight')['date'] = DateTime.now().toIso8601String();

      widget.vitalsByLOINC.firstWhere((vital) => vital['name'] == 'Height')['result'] = widget.healthHeight.toString();
      widget.vitalsByLOINC.firstWhere((vital) => vital['name'] == 'Weight')['result'] = widget.healthWeight.toString();
      widget.vitalsByLOINC.firstWhere((vital) => vital['name'] == 'Height')['date'] = DateTime.now().toIso8601String();
      widget.vitalsByLOINC.firstWhere((vital) => vital['name'] == 'Weight')['date'] = DateTime.now().toIso8601String();

      _showUpdateButton = false;
      _updateMessage = '';
    });
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
              title: Text('Vitals by Name'),
              children: widget.vitalsByName.map((vital) {
                return ListTile(
                  title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
                );
              }).toList(),
            ),
            ExpansionTile(
              title: Text('Vitals by LOINC'),
              children: widget.vitalsByLOINC.map((vital) {
                return ListTile(
                  title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
                );
              }).toList(),
            ),
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
            ]
          ],
        ),
      ),
    );
  }
}
