package com.smarttaxi.taxi_api.service;

import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.payload.request.TripRequest; 

public interface TripService {
    
    Trip createTrip(TripRequest request);
    Trip getTrip(String id);
    // Trong Interface TripService
    Trip getDriverCurrentTrip(String driverId);
}