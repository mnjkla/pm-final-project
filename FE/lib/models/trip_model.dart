class Trip {
  final String id;
  final String? driverId;
  final String status;
  // Bạn có thể thêm các trường khác nếu cần (price, driverName...)

  Trip({required this.id, this.driverId, required this.status});

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      driverId: json['driverId'],
      status: json['status'],
    );
  }
}