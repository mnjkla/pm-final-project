package com.smarttaxi.taxi_api.repository;

import java.time.LocalTime;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;

import com.smarttaxi.taxi_api.model.entity.PriceConfig;

public interface PriceConfigRepository extends MongoRepository<PriceConfig, String> {

    // QUERY: Tìm cấu hình giá có loại xe trùng khớp VÀ thời gian hiện tại nằm giữa giờ bắt đầu/kết thúc
    // ?0 là tham số thứ nhất (vehicleType)
    // ?1 là tham số thứ hai (currentTime)
    @Query("{ 'vehicleType': ?0, 'startTime': { $lte: ?1 }, 'endTime': { $gte: ?1 } }")
    Optional<PriceConfig> findByVehicleTypeAndJwtTime(String vehicleType, LocalTime currentTime);
}