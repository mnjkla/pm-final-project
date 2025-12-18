package com.smarttaxi.taxi_api.payload.request;

import lombok.Data;

@Data // Lombok tự sinh Getter/Setter
public class TripRequest {
    // Đây là các dữ liệu (Payload) mà App Flutter sẽ gửi lên
    
    private Double pickupLatitude;  // Vĩ độ điểm đón
    private Double pickupLongitude; // Kinh độ điểm đón
    
    private String destinationAddress; // Địa chỉ đến (tùy chọn)
    private Double destinationLatitude;
    private Double destinationLongitude;
    
    private String vehicleType; // Ví dụ: "BIKE", "CAR"
}