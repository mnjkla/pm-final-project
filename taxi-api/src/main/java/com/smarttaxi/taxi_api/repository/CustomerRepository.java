package com.smarttaxi.taxi_api.repository;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import com.smarttaxi.taxi_api.model.entity.Customer;

public interface CustomerRepository extends MongoRepository<Customer, String> {
    Optional<Customer> findByFirebaseId(String firebaseId);
}
