package com.smarttaxi.taxi_api.web;

import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.payload.request.TripRequest;
import com.smarttaxi.taxi_api.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/trips")
@RequiredArgsConstructor
public class TripController {

    private final TripService tripService;

    @PostMapping("/book")
    public ResponseEntity<Trip> bookTrip(@RequestBody TripRequest request) {
        // App gửi tọa độ điểm đón, Backend tìm xe và trả về thông tin chuyến
        return ResponseEntity.ok(tripService.createTrip(request));
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Trip> getTrip(@PathVariable String id) {
        return ResponseEntity.ok(tripService.getTrip(id));
    }
}