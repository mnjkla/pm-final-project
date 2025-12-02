package com.smarttaxi.taxi_api.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.smarttaxi.taxi_api.model.entity.User;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
}
