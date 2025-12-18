class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final double latitude;
  final double longitude;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.latitude,
    required this.longitude,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    // MongoDB GeoJsonPoint thường trả về: location: { x: ..., y: ..., coordinates: [long, lat] }
    // Lưu ý: MongoDB lưu [Longitude, Latitude]
    final coordinates = json['location'] != null ? json['location']['coordinates'] : [0.0, 0.0];

    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? 'BIKE',
      longitude: (coordinates[0] as num).toDouble(), // Kinh độ
      latitude: (coordinates[1] as num).toDouble(),  // Vĩ độ
    );
  }
}