class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;

  // THÊM: Thông tin chi tiết xe & Đánh giá
  final String vehiclePlate; // Biển số (29A-123.45)
  final String vehicleBrand; // Hãng (Honda Vision)
  final double rating;       // Điểm sao (4.9)

  final double latitude;
  final double longitude;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.vehicleBrand,
    required this.rating,
    required this.latitude,
    required this.longitude,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    final coordinates = json['location'] != null ? json['location']['coordinates'] : [0.0, 0.0];

    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Tài xế SmartTaxi',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? 'BIKE',

      // Map dữ liệu mới, có giá trị mặc định nếu null
      vehiclePlate: json['vehiclePlate'] ?? 'Đang cập nhật',
      vehicleBrand: json['vehicleBrand'] ?? 'Xe máy',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,

      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }
}