package com.smarttaxi.taxi_api.service;

import org.springframework.beans.factory.annotation.Value; // Import cái này
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FptAiService {

    // --- THAY ĐỔI Ở ĐÂY ---
    // Spring sẽ tìm dòng 'fpt.ai.api.key' trong file properties và gán vào biến này
    @Value("${fpt.ai.api.key}")
    private String fptApiKey;

    private static final String OCR_ENDPOINT = "https://api.fpt.ai/vision/dlr/vnm";

    public String scanIdCard(MultipartFile file) {
        try {
            RestTemplate restTemplate = new RestTemplate();

            HttpHeaders headers = new HttpHeaders();
            headers.set("api-key", fptApiKey); 
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename();
                }
            });

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(OCR_ENDPOINT, requestEntity, String.class);

            return response.getBody(); 

        } catch (Exception e) {
            throw new RuntimeException("Lỗi gọi FPT.AI: " + e.getMessage());
        }
    }
}