package com.smarttaxi.taxi_api.web;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping; // Import thêm cái này
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.repository.DriverRepository;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    @Autowired
    private DriverRepository driverRepository;

    @GetMapping("/fake") 
    public Driver createFakeDriver(@RequestParam String name, 
                                   @RequestParam double lat, 
                                   @RequestParam double lng) {
        // SỬA LỖI: Dùng Constructor rỗng + Setters
        Driver driver = new Driver();
        driver.setName(name);
        driver.setPhone("0909999999");
        driver.setOnline(true);
        driver.setVehicleType("BIKE");
        // Lưu ý: MongoDB lưu (Longitude, Latitude) -> (Kinh độ, Vĩ độ)
        driver.setLocation(new GeoJsonPoint(lng, lat)); 
        
        return driverRepository.save(driver);
    }

    @GetMapping("/nearby")
    public List<Driver> findNearby(@RequestParam double lat, 
                                   @RequestParam double lng) {
        // Lưu ý: Point của Spring Data Geo cũng là (x, y) -> (lng, lat)
        Point currentLocation = new Point(lng, lat);
        Distance radius = new Distance(5, Metrics.KILOMETERS); 
        return driverRepository.findByLocationNear(currentLocation, radius);
    }
    @GetMapping("/profile/{firebaseId}")
    public ResponseEntity<Driver> getDriverProfile(@PathVariable String firebaseId) {
        return driverRepository.findByFirebaseId(firebaseId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
}