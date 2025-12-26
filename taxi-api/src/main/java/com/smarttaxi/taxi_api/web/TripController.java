package com.smarttaxi.taxi_api.web;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
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

    private final TripServiceImpl tripService; 

    // API tạo chuyến đi mới (Khách hàng gọi)
    @PostMapping("/create")
    public ResponseEntity<Trip> createTrip(@RequestBody TripRequest request) {
        return ResponseEntity.ok(tripService.createTrip(request));
    }

    // API Tài xế nhận chuyến (Dùng POST vì thay đổi trạng thái)
    @PostMapping("/{id}/accept")
    public ResponseEntity<Trip> acceptTrip(@PathVariable String id) {
        return ResponseEntity.ok(tripService.driverAcceptTrip(id));
    }

    // API Tài xế từ chối chuyến
    @PostMapping("/{id}/reject")
    public ResponseEntity<Void> rejectTrip(@PathVariable String id) {
        tripService.driverRejectTrip(id);
        return ResponseEntity.ok().build();
    }
    
    // API Lấy chi tiết chuyến đi
    @GetMapping("/{id}")
    public ResponseEntity<Trip> getTrip(@PathVariable String id) {
        return ResponseEntity.ok(tripService.getTrip(id));
    }
}