package com.smarttaxi.taxi_api.service;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.rekognition.RekognitionClient;
import software.amazon.awssdk.services.rekognition.model.CompareFacesRequest;
import software.amazon.awssdk.services.rekognition.model.CompareFacesResponse;
import software.amazon.awssdk.services.rekognition.model.Image;

@Service
public class AwsRekognitionService {

    private final RekognitionClient rekognitionClient;

    public AwsRekognitionService() {
        // Khởi tạo Client (Nên để Key trong biến môi trường thay vì hardcode)
        this.rekognitionClient = RekognitionClient.builder()
                .region(Region.AP_SOUTHEAST_1) // Region Singapore (gần VN nhất)
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create("YOUR_ACCESS_KEY", "YOUR_SECRET_KEY")))
                .build();
    }

    public boolean compareFaces(MultipartFile sourceImage, MultipartFile targetImage) {
        try {
            // 1. Chuyển ảnh thành SdkBytes
            Image source = Image.builder().bytes(SdkBytes.fromInputStream(sourceImage.getInputStream())).build();
            Image target = Image.builder().bytes(SdkBytes.fromInputStream(targetImage.getInputStream())).build();

            // 2. Tạo Request so sánh
            CompareFacesRequest request = CompareFacesRequest.builder()
                    .sourceImage(source)
                    .targetImage(target)
                    .similarityThreshold(80F) // Độ giống nhau tối thiểu 80%
                    .build();

            // 3. Gọi AWS
            CompareFacesResponse response = rekognitionClient.compareFaces(request);

            // 4. Kiểm tra kết quả
            return !response.faceMatches().isEmpty(); // Nếu list không rỗng tức là khớp

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}