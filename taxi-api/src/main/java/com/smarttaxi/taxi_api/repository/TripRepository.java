package com.smarttaxi.taxi_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.model.entity.User;

public interface TripRepository extends JpaRepository<Trip, Long> {
    List<Trip> findByPassenger(User passenger);
}
