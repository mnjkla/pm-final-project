package com.smarttaxi.taxi_api.service;

import com.smarttaxi.taxi_api.model.entity.Trip;
// Bạn cần tạo class TripRequest (DTO) để nhận dữ liệu từ App
import com.smarttaxi.taxi_api.payload.request.TripRequest; 

public interface TripService {
    
    Trip createTrip(TripRequest request);
    Trip getTrip(String id);
}