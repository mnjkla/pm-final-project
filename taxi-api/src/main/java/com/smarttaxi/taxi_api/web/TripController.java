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
import com.smarttaxi.taxi_api.service.TripService;

import lombok.RequiredArgsConstructor;

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
    @GetMapping("/driver/current")
    public ResponseEntity<?> getDriverCurrentTrip() {
        // Lấy ID tài xế từ Token đăng nhập (hoặc truyền tạm qua param để test)
        // Giả sử bạn lấy được currentUserId từ SecurityContext
        String currentDriverId = "ID_CUA_TAI_XE_THAT"; // TODO: Thay bằng logic lấy ID thật
        
        // Nếu test nhanh, bạn truyền driverId qua @RequestParam cũng được
        
        Trip trip = tripService.getDriverCurrentTrip(currentDriverId);
        if (trip != null) {
            return ResponseEntity.ok(trip);
        } else {
            return ResponseEntity.noContent().build();
        }
    }
}