class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String? address1;
  final String? city;
  final String? email;
  final String? birthDate;
  final String? phone;
  final String? employerName;
  final String? state;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.address1,
    this.city,
    this.email,
    this.birthDate,
    this.phone,
    this.employerName,
    this.state,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['pat_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      address1: json['address1'] ?? '',
      city: json['city'] ?? '',
      email: json['email'] ?? '',
      birthDate: json['birth_date'] ?? '',
      phone: json['cell_phone'] ?? '',
      employerName: json['employer_name'] ?? '',
      state: json['state'] ?? '',
    );
  }
}
