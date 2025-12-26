class TripRequest {
  // Cập nhật mới: Thêm customerId để Backend biết ai đặt
  final String customerId;

  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;

  final String? destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final String vehicleType; // "BIKE", "CAR_4", "CAR_7"

  TripRequest({
    required this.customerId,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'vehicleType': vehicleType,
    };
  }
}