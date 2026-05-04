class Rider {
  final String id;
  final String name;
  final String phoneNumber;
  final bool isActive;

  Rider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.isActive,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
