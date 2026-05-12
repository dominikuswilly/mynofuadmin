class Rider {
  final String id;
  final String name;
  final String username;
  final String createdAt;
  final String whatsappNumber;
  final bool isActive;

  Rider({
    required this.id,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.whatsappNumber,
    required this.isActive,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'].toString(),
      name: json['name'] as String,
      username: json['username'] as String,
      createdAt: json['created_at'] as String,
      whatsappNumber: json['whatsapp_number'] as String,
      isActive: json['active'] == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rider && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
