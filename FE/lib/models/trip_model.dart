class Trip {
  final String id;
  final String? driverId;
  final String status;

  // THÊM: Thông tin chuyến đi chi tiết
  final double price;         // Giá tiền
  final double distance;      // Khoảng cách (km)
  final String pickupAddress;
  final String destinationAddress;

  Trip({
    required this.id,
    this.driverId,
    required this.status,
    required this.price,
    required this.distance,
    required this.pickupAddress,
    required this.destinationAddress,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      driverId: json['driverId'],
      status: json['status'] ?? 'UNKNOWN',

      // Xử lý số liệu an toàn (tránh crash app nếu null)
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      distance: (json['distance'] is num) ? (json['distance'] as num).toDouble() : 0.0,

      pickupAddress: json['pickupAddress'] ?? '',
      destinationAddress: json['destinationAddress'] ?? '',
    );
  }
}