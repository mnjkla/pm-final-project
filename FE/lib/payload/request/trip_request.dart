class TripRequest {
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final String? destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String vehicleType; // "BIKE", "CAR"

  TripRequest({
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.vehicleType,
  });

  // Biến object thành JSON để gửi qua mạng
  Map<String, dynamic> toJson() {
    return {
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