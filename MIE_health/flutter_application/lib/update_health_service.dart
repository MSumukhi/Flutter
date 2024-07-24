import 'package:health/health.dart';

HealthFactory _health = HealthFactory();

Future<bool> updateHealthHeight(double heightInFeet, DateTime timestamp) async {
  double heightInMeters = feetToMeters(heightInFeet);
  print('Height being updated to Health app (in meters): $heightInMeters');
  var types = [HealthDataType.HEIGHT];
  var permissions = [HealthDataAccess.WRITE];

  bool requested = await _health.requestAuthorization(types, permissions: permissions);
  if (requested) {
    try {
      bool success = await _health.writeHealthData(heightInMeters, HealthDataType.HEIGHT, timestamp, timestamp);
      if (success) {
        print('Successfully updated health height data.');
        return true;
      } else {
        print('Failed to update health height data.');
        return false;
      }
    } catch (e) {
      print('Error updating health height data: $e');
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
