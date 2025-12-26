// File: src/main/java/com/smarttaxi/taxi_api/web/TripController.java
package com.smarttaxi.taxi_api.web;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping; // Cần cast để gọi hàm mới hoặc thêm vào interface
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.payload.request.TripRequest;
import com.smarttaxi.taxi_api.service.impl.TripServiceImpl;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/trips")
@RequiredArgsConstructor
public class TripController {

    private final TripServiceImpl tripService; // Inject TripServiceImpl để gọi hàm mới

    @PostMapping("/create")
    public ResponseEntity<Trip> createTrip(@RequestBody TripRequest request) {
        return ResponseEntity.ok(tripService.createTrip(request));
    }

    @PostMapping("/{id}/accept") 
    public ResponseEntity<Trip> acceptTrip(@PathVariable String id) {
    return ResponseEntity.ok(tripService.driverAcceptTrip(id));
}

    @PostMapping("/{id}/reject")
    public ResponseEntity<Void> rejectTrip(@PathVariable String id) {
        tripService.driverRejectTrip(id);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Trip> getTrip(@PathVariable String id) {
        return ResponseEntity.ok(tripService.getTrip(id));
    }
}