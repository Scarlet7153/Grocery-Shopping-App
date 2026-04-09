package com.grocery.server.upload.controller;

import com.grocery.server.order.entity.Order;
import com.grocery.server.order.repository.OrderRepository;
import com.grocery.server.product.entity.Product;
import com.grocery.server.product.repository.ProductRepository;
import com.grocery.server.shared.dto.ApiResponse;
import com.grocery.server.store.entity.Store;
import com.grocery.server.store.repository.StoreRepository;
import com.grocery.server.upload.service.CloudinaryUploadService;
import com.grocery.server.user.entity.User;
import com.grocery.server.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import com.grocery.server.user.service.UserService;

import java.io.IOException;

/**
 * Controller: ImageUploadController
 * Mục đích: REST API upload ảnh lên Cloudinary
 * 
 * Endpoints:
 * Product:
 *  - POST /api/upload/product          - Upload ảnh sản phẩm tạm thời (trước khi tạo product) → return imageUrl
 *  - POST /api/upload/product/{id}     - Upload & cập nhật ảnh vào product (sau khi tạo)
 * 
 * Store:
 *  - POST /api/upload/store/{storeId}  - Upload ảnh store
 * 
 * User:
 *  - POST /api/upload/avatar           - Upload avatar user
 * 
 * Order:
 *  - POST /api/upload/pod/{orderId}    - Upload ảnh POD (shipper)
 *
 * Delete:
 *  - DELETE /api/upload/image          - Xóa ảnh từ Cloudinary (ADMIN only)
 */
@RestController
@RequestMapping("/upload")
@RequiredArgsConstructor
@Slf4j
public class ImageUploadController {

    private final CloudinaryUploadService uploadService;
    private final ProductRepository productRepository;
    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final UserService userService;

    /**
     * Upload ảnh sản phẩm tạm thời (trước khi tạo product)
     * Chỉ STORE và ADMIN có quyền
     * 
     * Flow:
     * 1. Upload ảnh → return imageUrl
     * 2. Tạo product với imageUrl này
     * 
     * Recommended: Gọi endpoint này để upload ảnh trước, sau đó POST /api/products với imageUrl
     */
    @PostMapping("/product")
    @PreAuthorize("hasAnyRole('STORE', 'ADMIN')")
    public ResponseEntity<ApiResponse<String>> uploadProductTempImage(
            @RequestParam("file") MultipartFile file) {
        
        log.info("Uploading temp product image");
        
        try {
            // Upload ảnh
            String imageUrl = uploadService.uploadProductImage(file);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Upload ảnh sản phẩm thành công", imageUrl)
            );
            
        } catch (IOException e) {
            log.error("Error uploading product image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi upload ảnh: " + e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Upload ảnh sản phẩm và cập nhật vào product (nếu product đã tồn tại)
     * Chỉ STORE và ADMIN có quyền
     * 
     * Dùng sau khi đã tạo product, nếu muốn cập nhật ảnh
     */
    @PostMapping("/product/{productId}")
    @PreAuthorize("hasAnyRole('STORE', 'ADMIN')")
    public ResponseEntity<ApiResponse<String>> updateProductImage(
            @PathVariable Long productId,
            @RequestParam("file") MultipartFile file) {
        
        log.info("Uploading image for product {}", productId);
        
        try {
            // Kiểm tra product tồn tại
            Product product = productRepository.findById(productId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Product not found: " + productId));
            
            // Upload ảnh
            String imageUrl = uploadService.uploadProductImage(file);
            
            // Cập nhật URL vào database
            product.setImageUrl(imageUrl);
            productRepository.save(product);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Upload ảnh sản phẩm thành công", imageUrl)
            );
            
        } catch (IOException e) {
            log.error("Error uploading product image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi upload ảnh: " + e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Upload ảnh cửa hàng
     * Chỉ STORE và ADMIN có quyền
     */
    @PostMapping("/store/{storeId}")
    @PreAuthorize("hasAnyRole('STORE', 'ADMIN')")
    public ResponseEntity<ApiResponse<String>> uploadStoreImage(
            @PathVariable Long storeId,
            @RequestParam("file") MultipartFile file) {
        
        log.info("Uploading image for store {}", storeId);
        
        try {
            // Kiểm tra store tồn tại
            Store store = storeRepository.findById(storeId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Store not found: " + storeId));
            
            // Upload ảnh
            String imageUrl = uploadService.uploadStoreImage(file);
            
            // Cập nhật URL vào database
            store.setImageUrl(imageUrl);
            storeRepository.save(store);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Upload ảnh cửa hàng thành công", imageUrl)
            );
            
        } catch (IOException e) {
            log.error("Error uploading store image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi upload ảnh: " + e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Upload avatar user
     * User nào cũng có thể upload avatar của mình
     */
    @PostMapping("/avatar")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<String>> uploadAvatar(
            @RequestParam("file") MultipartFile file) {
        
        Long currentUserId = userService.getCurrentUserId();
        log.info("Uploading avatar for user {}", currentUserId);
        
        try {
            // Kiểm tra user tồn tại
            User user = userRepository.findById(currentUserId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "User not found: " + currentUserId));
            
            // Xóa ảnh cũ nếu có
            if (user.getAvatarUrl() != null) {
                uploadService.deleteImage(user.getAvatarUrl());
            }
            
            // Upload ảnh mới
            String imageUrl = uploadService.uploadUserAvatar(file);
            
            // Cập nhật URL vào database
            user.setAvatarUrl(imageUrl);
            userRepository.save(user);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Upload avatar thành công", imageUrl)
            );
            
        } catch (IOException e) {
            log.error("Error uploading avatar: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi upload ảnh: " + e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Upload ảnh POD (Proof of Delivery)
     * Chỉ SHIPPER được upload
     */
    @PostMapping("/pod/{orderId}")
    @PreAuthorize("hasRole('SHIPPER')")
    public ResponseEntity<ApiResponse<String>> uploadPODImage(
            @PathVariable Long orderId,
            @RequestParam("file") MultipartFile file) {
        
        Long currentUserId = userService.getCurrentUserId();
        log.info("Uploading POD image for order {} by shipper {}", orderId, currentUserId);
        
        try {
            // Kiểm tra order tồn tại
            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND, "Order not found: " + orderId));
            
            // Kiểm tra shipper có quyền với order này không
            if (order.getShipper() == null || !order.getShipper().getId().equals(currentUserId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(ApiResponse.error("Bạn không có quyền upload POD cho đơn hàng này"));
            }
            
            // Upload ảnh
            String imageUrl = uploadService.uploadPODImage(file, orderId);
            
            // Cập nhật URL vào database
            order.setPodImageUrl(imageUrl);
            orderRepository.save(order);
            
            return ResponseEntity.ok(
                    ApiResponse.success("Upload ảnh POD thành công", imageUrl)
            );
            
        } catch (IOException e) {
            log.error("Error uploading POD image: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi upload ảnh: " + e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }

    /**
     * Xóa ảnh từ Cloudinary
     * Chỉ ADMIN có quyền
     */
    @DeleteMapping("/image")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteImage(@RequestParam("url") String imageUrl) {
        log.info("Deleting image: {}", imageUrl);
        
        uploadService.deleteImage(imageUrl);
        
        return ResponseEntity.ok(
                ApiResponse.success("Xóa ảnh thành công", null)
        );
    }
}
