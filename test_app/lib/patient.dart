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
    );
  }
}
