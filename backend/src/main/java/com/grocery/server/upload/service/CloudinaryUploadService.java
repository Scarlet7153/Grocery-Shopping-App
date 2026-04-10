package com.grocery.server.upload.service;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Service: CloudinaryUploadService
 * Mục đích: Xử lý upload ảnh lên Cloudinary
 * 
 * Supported upload types:
 * - Product images
 * - Store images  
 * - User avatars
 * - POD (Proof of Delivery) images
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CloudinaryUploadService {

    private final Cloudinary cloudinary;

    @Value("${cloudinary.cloud-name}")
    private String cloudName;

    @Value("${cloudinary.api-key}")
    private String apiKey;

    @Value("${cloudinary.api-secret}")
    private String apiSecret;

    /**
     * Tạo chữ ký upload trực tiếp Cloudinary cho avatar.
     *
     * Flow client:
     * 1. Gọi endpoint lấy signature params
     * 2. Upload trực tiếp lên Cloudinary từ mobile
     * 3. Gọi endpoint save avatar URL vào DB
     */
    public Map<String, Object> generateSignedAvatarUploadParams(Long userId) {
        long timestamp = Instant.now().getEpochSecond();
        String folder = "grocery-app/avatars";
        String publicId = "user-" + userId + "-" + timestamp;

        Map<String, Object> paramsToSign = new HashMap<>();
        paramsToSign.put("folder", folder);
        paramsToSign.put("public_id", publicId);
        paramsToSign.put("timestamp", timestamp);

        String signature = cloudinary.apiSignRequest(paramsToSign, apiSecret);

        Map<String, Object> response = new HashMap<>();
        response.put("cloudName", cloudName);
        response.put("apiKey", apiKey);
        response.put("timestamp", timestamp);
        response.put("folder", folder);
        response.put("publicId", publicId);
        response.put("signature", signature);
        response.put("uploadUrl", "https://api.cloudinary.com/v1_1/" + cloudName + "/image/upload");
        return response;
    }

    /**
     * Upload ảnh lên Cloudinary
     * 
     * @param file File ảnh cần upload
     * @param folder Thư mục trên Cloudinary (products, stores, avatars, pod)
     * @return URL của ảnh đã upload
     */
    public String uploadImage(MultipartFile file, String folder) throws IOException {
        log.info("Uploading image to Cloudinary folder: {}", folder);
        
        // Validate file
        validateImageFile(file);
        
        // Upload options
        Map<String, Object> uploadOptions = ObjectUtils.asMap(
            "folder", "grocery-app/" + folder,
            "resource_type", "image",
            "use_filename", true,
            "unique_filename", true,
            "overwrite", false
        );
        
        // Upload file
        Map<?, ?> uploadResult = cloudinary.uploader().upload(file.getBytes(), uploadOptions);
        
        String imageUrl = uploadResult.get("secure_url").toString();
        log.info("Image uploaded successfully. URL: {}", imageUrl);
        
        return imageUrl;
    }

    /**
     * Upload ảnh product
     */
    public String uploadProductImage(MultipartFile file) throws IOException {
        return uploadImage(file, "products");
    }

    /**
     * Upload ảnh store
     */
    public String uploadStoreImage(MultipartFile file) throws IOException {
        return uploadImage(file, "stores");
    }

    /**
     * Upload avatar user
     */
    public String uploadUserAvatar(MultipartFile file) throws IOException {
        return uploadImage(file, "avatars");
    }

    /**
     * Upload ảnh POD (Proof of Delivery)
     */
    public String uploadPODImage(MultipartFile file, Long orderId) throws IOException {
        return uploadImage(file, "pod/order-" + orderId);
    }

    /**
     * Xóa ảnh từ Cloudinary
     * 
     * @param imageUrl URL của ảnh cần xóa
     */
    public void deleteImage(String imageUrl) {
        try {
            log.info("Deleting image from Cloudinary: {}", imageUrl);
            
            // Extract public_id từ URL
            String publicId = extractPublicId(imageUrl);
            
            if (publicId != null) {
                cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap());
                log.info("Image deleted successfully: {}", publicId);
            }
        } catch (Exception e) {
            log.error("Error deleting image: {}", e.getMessage());
        }
    }

    /**
     * Validate file ảnh
     */
    private void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File không được để trống");
        }

        // Kiểm tra content type
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("File phải là định dạng ảnh (JPEG, PNG, JPG)");
        }

        // Kiểm tra kích thước (max 10MB đã config trong application.properties)
        if (file.getSize() > 10 * 1024 * 1024) {
            throw new IllegalArgumentException("File ảnh không được vượt quá 10MB");
        }
    }

    /**
     * Extract public_id từ Cloudinary URL
     * 
     * URL format: https://res.cloudinary.com/{cloud_name}/image/upload/{version}/{folder}/{filename}
     * public_id: {folder}/{filename}
     */
    private String extractPublicId(String imageUrl) {
        try {
            if (imageUrl == null || !imageUrl.contains("cloudinary.com")) {
                return null;
            }
            
            // Tìm vị trí sau "upload/"
            String[] parts = imageUrl.split("/upload/");
            if (parts.length > 1) {
                // Bỏ qua version (v1234567890) nếu có
                String path = parts[1];
                if (path.startsWith("v")) {
                    path = path.substring(path.indexOf("/") + 1);
                }
                // Bỏ extension
                if (path.contains(".")) {
                    path = path.substring(0, path.lastIndexOf("."));
                }
                return path;
            }
        } catch (Exception e) {
            log.error("Error extracting public_id: {}", e.getMessage());
        }
        return null;
    }
}
