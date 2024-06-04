class Patient {
  final String id;
  final String firstName;
  final String lastName;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['pat_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}