package com.smarttaxi.taxi_api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.repository.MongoRepository;

import com.smarttaxi.taxi_api.model.entity.Driver;


public interface DriverRepository extends MongoRepository<Driver, String> {

    
   
    List<Driver> findByLocationNear(Point location, Distance distance);
    
    
    List<Driver> findByIsOnlineTrueAndLocationNear(Point location, Distance distance);
    
    Optional<Driver> findByFirebaseId(String firebaseId);
}