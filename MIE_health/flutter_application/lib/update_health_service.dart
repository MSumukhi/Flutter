// update_health_service.dart
import 'package:health/health.dart';

HealthFactory _health = HealthFactory();

Future<bool> updateHealthHeight(double heightInInches, DateTime timestamp) async {
  double heightInFeet = inchesToFeet(heightInInches);
  var types = [HealthDataType.HEIGHT];
  var permissions = [HealthDataAccess.WRITE];

  bool requested = await _health.requestAuthorization(types, permissions: permissions);
  if (requested) {
    try {
      bool success = await _health.writeHealthData(heightInFeet, HealthDataType.HEIGHT, timestamp, timestamp);
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

double inchesToFeet(double inches) {
  return inches / 12.0;
}
