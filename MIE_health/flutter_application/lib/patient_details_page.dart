import 'package:flutter/material.dart';
import 'webchart_service.dart'; // Import the webchart_service.dart

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> vitals;
  final double healthHeight;
  final double healthWeight;

  const PatientDetailsPage({super.key, required this.patientData, required this.vitals, required this.healthHeight, required this.healthWeight});

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  @override
  void initState() {
    super.initState();
    _compareAndUpdateVitals();
  }

  void _compareAndUpdateVitals() {
    double webChartHeight = double.parse(widget.vitals.firstWhere((vital) => vital['name'] == 'Height')['result']);
    double webChartWeight = double.parse(widget.vitals.firstWhere((vital) => vital['name'] == 'Weight')['result']);

    if (widget.healthHeight != webChartHeight || widget.healthWeight != webChartWeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateDialog();
      });
    }
  }

  Future<void> _showUpdateDialog() async {
    bool update = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update WebChart Data'),
          content: Text('There are differences between Health data and WebChart data for height and weight. Do you want to update WebChart with the latest Health data?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (update) {
      await updateWebChartWithHealthData(widget.patientData['pat_id'], widget.healthHeight, widget.healthWeight);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WebChart updated successfully.')));
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
              ],
            ),
            ExpansionTile(
              title: Text('Vitals'),
              children: widget.vitals.map((vital) {
                return ListTile(
                  title: Text('${vital['name']}: ${vital['result']} ${vital['units']} (${vital['date']})'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
