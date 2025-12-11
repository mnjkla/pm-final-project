package com.smarttaxi.taxi_api.web; // Nhớ package phải đúng

import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/drivers")
public class DriverController {

    @Autowired
    private DriverRepository driverRepository;

    
    @GetMapping("/fake") 
    public Driver createFakeDriver(@RequestParam String name, 
                                   @RequestParam double lat, 
                                   @RequestParam double lng) {
        return driverRepository.save(new Driver(name, "0909999999", lng, lat));
    }

    @GetMapping("/nearby")
    public List<Driver> findNearby(@RequestParam double lat, 
                                   @RequestParam double lng) {
        Point currentLocation = new Point(lng, lat);
        Distance radius = new Distance(5, Metrics.KILOMETERS); 
        return driverRepository.findByLocationNear(currentLocation, radius);
    }
}