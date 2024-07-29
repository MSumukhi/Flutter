import 'package:health/health.dart';

HealthFactory _health = HealthFactory();

Future<bool> updateHealthData(HealthDataType type, double value, DateTime timestamp) async {
  print('Data being updated to Health app (type: $type): $value');
  var types = [type];
  var permissions = [HealthDataAccess.WRITE];

  bool requested = await _health.requestAuthorization(types, permissions: permissions);
  if (requested) {
    try {
      bool success = await _health.writeHealthData(value, type, timestamp, timestamp);
      if (success) {
        print('Successfully updated health data (type: $type).');
        return true;
      } else {
        print('Failed to update health data (type: $type).');
        return false;
      }
    } catch (e) {
      print('Error updating health data (type: $type): $e');
      return false;
    }
  } else {
    print('Authorization not granted.');
    return false;
  }
}

double feetToMeters(double feet) {
  return feet * 0.3048;
}

double poundsToKg(double pounds) {
  return pounds * 0.453592;
}
