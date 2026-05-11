/// UserProfile model for storing customer personal information.
class UserProfile {
  final String uid;
  final String firstName;
  final String middleInitial;
  final String lastName;
  final String phoneNumber;
  final String street;
  final String barangay;
  final String municipality;
  final String city;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.firstName,
    required this.middleInitial,
    required this.lastName,
    required this.phoneNumber,
    required this.street,
    required this.barangay,
    required this.municipality,
    required this.city,
    required this.country,
    this.createdAt,
    this.updatedAt,
  });

  /// Computed full name
  String get fullName =>
      '$firstName ${middleInitial.isNotEmpty ? '$middleInitial ' : ''}$lastName'
          .trim();

  /// Computed full address
  String get address =>
      '$street, $barangay, $municipality, $city, $country'.trim();

  /// Convert UserProfile to a Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'middleInitial': middleInitial,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'street': street,
      'barangay': barangay,
      'municipality': municipality,
      'city': city,
      'country': country,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create UserProfile from Firebase Map data
  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      uid: map['uid']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      middleInitial: map['middleInitial']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      street: map['street']?.toString() ?? '',
      barangay: map['barangay']?.toString() ?? '',
      municipality: map['municipality']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      country: map['country']?.toString() ?? 'Philippines',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  /// Check if profile is complete (all fields filled)
  bool get isComplete =>
      uid.isNotEmpty &&
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      phoneNumber.isNotEmpty &&
      street.isNotEmpty &&
      barangay.isNotEmpty &&
      municipality.isNotEmpty &&
      city.isNotEmpty &&
      country.isNotEmpty;

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? uid,
    String? firstName,
    String? middleInitial,
    String? lastName,
    String? phoneNumber,
    String? street,
    String? barangay,
    String? municipality,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      middleInitial: middleInitial ?? this.middleInitial,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
