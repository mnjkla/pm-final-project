package com.smarttaxi.taxi_api.web;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.smarttaxi.taxi_api.model.entity.Customer;
import com.smarttaxi.taxi_api.repository.CustomerRepository;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {
    @Autowired private CustomerRepository customerRepository;

    @GetMapping("/profile/{firebaseId}")
    public ResponseEntity<Customer> getProfile(@PathVariable String firebaseId) {
        return customerRepository.findByFirebaseId(firebaseId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    // API tạo mới khách hàng khi đăng ký lần đầu 
    @PostMapping("/register")
    public Customer register(@RequestBody Customer customer) {
        return customerRepository.save(customer);
    }
}