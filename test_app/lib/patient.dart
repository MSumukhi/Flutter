class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String address1;
  final String city;
  final String state;
  final String zipCode;
  final String email;
  final String birthDate;
  final String phone;
  final String employerName;
  List<Observation> vitals;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.address1 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.email = '',
    this.birthDate = '',
    this.phone = '',
    this.employerName = '',
    this.vitals = const [],
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['pat_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      address1: json['address1'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'] ?? '',
      email: json['email'] ?? '',
      birthDate: json['birth_date'] ?? '',
      phone: json['cell_phone'] ?? '',
      employerName: json['employer_name'] ?? '',
      vitals: [],
    );
  }
}

class Observation {
  final String id;
  final String patientId;
  final String name;
  final String result;
  final String dateTime;
  final String units;

  Observation({
    required this.id,
    required this.patientId,
    required this.name,
    required this.result,
    required this.dateTime,
    required this.units,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['obs_id'],
      patientId: json['pat_id'],
      name: json['obs_name'],
      result: json['obs_result'],
      dateTime: json['observed_datetime'],
      units: json['obs_units'] ?? '',
    );
  }
}
