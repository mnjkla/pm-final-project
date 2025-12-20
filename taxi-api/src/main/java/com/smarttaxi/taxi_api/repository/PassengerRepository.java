package com.smarttaxi.taxi_api.repository;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.smarttaxi.taxi_api.model.entity.Passenger;

public interface PassengerRepository extends MongoRepository<Passenger, String> {
    Optional<Passenger> findByFirebaseId(String firebaseId);
}