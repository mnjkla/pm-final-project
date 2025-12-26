// File: src/main/java/com/smarttaxi/taxi_api/service/FirebaseService.java
package com.smarttaxi.taxi_api.service;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.smarttaxi.taxi_api.model.entity.Trip;

@Service
public class FirebaseService {

    public void notifyDriverNewTrip(String driverId, Trip trip) {
        // Lưu thông tin chuyến đi vào node: drivers/{driverId}/trip_request
        DatabaseReference ref = FirebaseDatabase.getInstance().getReference("drivers/" + driverId + "/trip_request");

        Map<String, Object> requestData = new HashMap<>();
        requestData.put("tripId", trip.getId());
        requestData.put("pickupAddress", trip.getPickupAddress());
        requestData.put("destinationAddress", trip.getDestinationAddress());
        requestData.put("price", trip.getPrice());
        requestData.put("distance", trip.getDistance());
        requestData.put("timestamp", System.currentTimeMillis());

        ref.setValueAsync(requestData);
    }

    public void clearDriverRequest(String driverId) {
        // Xóa yêu cầu sau khi tài xế đã phản hồi
        DatabaseReference ref = FirebaseDatabase.getInstance().getReference("drivers/" + driverId + "/trip_request");
        ref.removeValueAsync();
    }
}