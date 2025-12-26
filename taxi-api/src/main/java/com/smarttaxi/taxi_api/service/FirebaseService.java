package com.smarttaxi.taxi_api.service;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.smarttaxi.taxi_api.model.entity.Trip;

@Service
public class FirebaseService {

    public void notifyDriverNewTrip(String driverFirebaseId, Trip trip) {
        if (driverFirebaseId == null || driverFirebaseId.isEmpty()) return;

        DatabaseReference ref = FirebaseDatabase.getInstance().getReference("drivers/" + driverFirebaseId + "/trip_request");

        // 🟢 QUAN TRỌNG: Chuyển đổi Trip thành Map phẳng (Flatten) để App dễ lấy
        Map<String, Object> tripData = new HashMap<>();
        tripData.put("tripId", trip.getId());
        tripData.put("customerId", trip.getCustomerId());
        tripData.put("price", trip.getPrice());
        tripData.put("distance", trip.getDistance());
        
        tripData.put("pickupAddress", trip.getPickupAddress());
        tripData.put("destinationAddress", trip.getDestinationAddress());

        // 👇 XỬ LÝ TỌA ĐỘ CẨN THẬN (Để App không bị lỗi điểm đến)
        if (trip.getPickupLocation() != null) {
            // Lưu ý: GeoJsonPoint getX() là Longitude (Kinh độ), getY() là Latitude (Vĩ độ)
            tripData.put("pickupLat", trip.getPickupLocation().getY());
            tripData.put("pickupLng", trip.getPickupLocation().getX());
        }

        if (trip.getDestinationLocation() != null) {
            tripData.put("destinationLat", trip.getDestinationLocation().getY());
            tripData.put("destinationLng", trip.getDestinationLocation().getX());
        }
        
        // Thêm thông tin khách (Demo)
        tripData.put("customerPhone", "0909.123.456"); 

        // Gửi lên Firebase
        ref.setValueAsync(tripData);
    }

    public void clearDriverRequest(String driverFirebaseId) {
        if (driverFirebaseId == null) return;
        DatabaseReference ref = FirebaseDatabase.getInstance().getReference("drivers/" + driverFirebaseId + "/trip_request");
        ref.removeValueAsync();
    }
}