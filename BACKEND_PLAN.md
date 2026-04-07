# BACKEND DEVELOPMENT PLAN - Grocery Shopping App
### Module 1: Authentication & Authorization 
- [x] User Entity với roles (CUSTOMER, SHIPPER, STORE, ADMIN)
- [x] JWT Token Provider
- [x] Security Configuration (Spring Security)
- [x] Authentication Filter
- [x] Custom UserDetailsService
- [x] Register API
- [x] Login API
- [x] Get Current User API (/auth/me)
- [x] Logout API
- [x] Refresh Token API
- [x] DTOs: LoginRequest, RegisterRequest, AuthResponse
- [x] Custom Exceptions: ResourceNotFoundException, BadRequestException, UnauthorizedException
- [x] GlobalExceptionHandler với exception handling đầy đủ

### Module 2: User Management 
- [x] UserRepository với custom queries
- [x] UserService với business logic
- [x] UserController với REST APIs
- [x] DTOs: UpdateProfileRequest, ChangePasswordRequest, UserProfileResponse, UserListResponse
- [x] Get Profile API
- [x] Update Profile API
- [x] Change Password API
- [x] Admin: Get All Users
- [x] Admin: Get Users by Role
- [x] Admin: Toggle User Status (Ban/Unban)
- [x] Admin: Delete User

### Module 3: Store Management 
- [x] Store Entity
- [x] StoreRepository với custom queries
- [x] Store DTOs (CreateStoreRequest, UpdateStoreRequest, StoreResponse)
- [x] StoreService với business logic
- [x] StoreController với REST APIs
- [x] APIs: GET /stores, GET /stores/{id}, GET /stores/my-store, PUT /stores/{id}, PATCH /stores/{id}/toggle-status, GET /stores/search
- [ ] Một số tối ưu hóa query còn thiếu

### Module 4: Product Management 
- [x] **Category Entity** 
  - [x] Review relationships
- [x] **Product Entity** 
  - [x] Review relationships
- [x] **ProductUnit Entity** 
  - [x] Review relationships với OrderItem
- [x] **CategoryRepository**
  - [x] findAll (list categories)
  - [x] findByName
  - [x] existsByName
- [x] **ProductRepository**
  - [x] findByStoreId
  - [x] findByCategoryId 
  - [x] findByStatus
  - [x] searchByKeyword
  - [x] findByStoreIdAndStatus
  - [x] findAvailableProductsByStore
  - [x] countByCategoryId
- [x] **Category DTOs**
  - [x] CreateCategoryRequest
  - [x] UpdateCategoryRequest
  - [x] CategoryResponse
- [x] **Product DTOs**
  - [x] CreateProductRequest
  - [x] UpdateProductRequest
  - [x] ProductResponse (với units)
  - [x] ProductUnitRequest
- [x] **CategoryService**
  - [x] getAllCategories
  - [x] getCategoryById
  - [x] createCategory (admin)
  - [x] updateCategory (admin)
  - [x] deleteCategory (admin)
- [x] **ProductService**
  - [x] createProduct (store owner)
  - [x] updateProduct (store owner)
  - [x] deleteProduct (store owner)
  - [x] getProductById
  - [x] getAllProducts
  - [x] getProductsByStore
  - [x] getProductsByCategory ✅ MỚI
  - [x] getAvailableProductsByStore
  - [x] searchProducts
  - [x] toggleProductStatus
- [x] **CategoryController** - `/api/categories`
  - [x] GET /api/categories (all categories - public)
  - [x] GET /api/categories/{id} (public)
  - [x] POST /api/categories (admin only - @PreAuthorize)
  - [x] PUT /api/categories/{id} (admin only - @PreAuthorize)
  - [x] DELETE /api/categories/{id} (admin only - @PreAuthorize)
- [x] **ProductController** - `/api/products`
  - [x] POST /api/products (store owner - @PreAuthorize)
  - [x] PUT /api/products/{id} (store owner - @PreAuthorize)
  - [x] DELETE /api/products/{id} (store owner - @PreAuthorize)
  - [x] PATCH /api/products/{id}/toggle-status (store owner - @PreAuthorize)
  - [x] GET /api/products (all products - public)
  - [x] GET /api/products/{id} (public)
  - [x] GET /api/products/store/{storeId} (public)
  - [x] GET /api/products/store/{storeId}/available (public)
  - [x] GET /api/products/category/{categoryId} (public)
  - [x] GET /api/products/search?keyword=... (public)

---


### Module 5: Order Management ✅ (COMPLETED)
- [x] **Order Entity** 
  - [x] Relationships: @ManyToOne với Customer, Store, Shipper
  - [x] @OneToMany với OrderItems
  - [x] Enum OrderStatus: PENDING, CONFIRMED, PICKING_UP, DELIVERING, DELIVERED, CANCELLED
- [x] **OrderItem Entity** 
  - [x] Relationships: @ManyToOne với Order, Product, ProductUnit
- [x] **OrderRepository**
  - [x] findByCustomerId
  - [x] findByStoreId
  - [x] findByShipperId
  - [x] findByStatus
  - [x] findAvailableOrdersForShipper (for shippers)
- [x] **OrderItemRepository**
  - [x] findByOrderId
- [x] **Order DTOs**
  - [x] CreateOrderRequest (với List<OrderItemRequest>)
  - [x] UpdateOrderStatusRequest
  - [x] OrderResponse (detailed với OrderItems list)
  - [x] OrderItemRequest (productUnitId, quantity)
  - [x] OrderItemResponse (full product info)
- [x] **OrderService** (với State Machine logic)
  - [x] createOrder (customer) - tính tổng tiền + phí ship 15,000đ
  - [x] getMyOrders (customer)
  - [x] getOrderById (with authorization check)
  - [x] getOrdersByStoreOwner (store owner) - 🔒 Security: lấy từ token
  - [x] getMyDeliveries (shipper)
  - [x] getAvailableOrders (shipper)
  - [x] assignShipperToOrder (shipper)
  - [x] updateOrderStatus (with role-based state machine)
  - [x] calculateTotalAmount (helper method)
- [x] **OrderController** (8 endpoints)
  - [x] POST /api/orders (create order - CUSTOMER)
  - [x] GET /api/orders/my-orders (customer orders)
  - [x] GET /api/orders/{id} (order detail - authorized)
  - [x] GET /api/orders/my-store-orders (store orders - 🔒 từ token)
  - [x] GET /api/orders/my-deliveries (shipper deliveries)
  - [x] GET /api/orders/available (available orders - SHIPPER)
  - [x] PATCH /api/orders/{id}/status (update status with state machine)
  - [x] POST /api/orders/{id}/assign-shipper (shipper accept order)
- [x] **Security Enhancement**
  - [x] Store endpoint không dùng storeId parameter
  - [x] Store orders được filter theo token của user
  - [x] Validation role trước khi truy cập orders
- [x] **Documentation**
  - [x] ORDER_REQUESTS_FOR_POSTMAN.md (8 endpoints + E2E scenarios)

### Module 6: Payment Management ⏳
- [ ] **Payment Entity** (đã có base)
  - [ ] Review relationships
- [ ] **PaymentRepository**
  - [ ] findByOrderId
  - [ ] findByCustomerId
  - [ ] findByStatus
- [ ] **Payment DTOs**
  - [ ] CreatePaymentRequest
  - [ ] PaymentResponse
  - [ ] PaymentListResponse
- [ ] **PaymentService**
  - [ ] createPayment
  - [ ] getPaymentByOrderId
  - [ ] updatePaymentStatus
  - [ ] processPayment (integration với payment gateway)
  - [ ] refundPayment
- [ ] **PaymentController**
  - [ ] POST /api/payments (create payment)
  - [ ] GET /api/payments/order/{orderId}
  - [ ] GET /api/payments/{id}
  - [ ] PATCH /api/payments/{id}/status
  - [ ] POST /api/payments/{id}/refund (admin)

### Module 7: Review & Rating ✅ (COMPLETED)
- [x] **Review Entity** (đã có base)
  - [x] Review relationships
- [x] **ReviewRepository**
  - [x] findByStoreId
  - [x] findByReviewerId
  - [x] findByOrderId
  - [x] existsByOrderId
  - [x] calculateAverageRating (custom query)
  - [x] countByStoreId
- [x] **Review DTOs**
  - [x] CreateReviewRequest
  - [x] UpdateReviewRequest
  - [x] ReviewResponse
  - [x] StoreRatingResponse
- [x] **ReviewService**
  - [x] createReview (customer only after order delivered)
  - [x] updateReview (only review owner)
  - [x] deleteReview (review owner or admin)
  - [x] getReviewById
  - [x] getReviewsByStore
  - [x] getMyReviews
  - [x] getStoreRating (average + total count)
- [x] **ReviewController** (7 endpoints)
  - [x] POST /api/reviews (create review - CUSTOMER)
  - [x] PUT /api/reviews/{id} (update - CUSTOMER owner)
  - [x] DELETE /api/reviews/{id} (delete - CUSTOMER/ADMIN)
  - [x] GET /api/reviews/{id} (get review - public)
  - [x] GET /api/reviews/store/{storeId} (store reviews - public)
  - [x] GET /api/reviews/my-reviews (my reviews - CUSTOMER)
  - [x] GET /api/reviews/store/{storeId}/rating (store rating - public)
- [x] **Business Rules Implemented**
  - [x] Only DELIVERED orders can be reviewed
  - [x] Only order owner can review
  - [x] One review per order
  - [x] Rating validation (1-5 stars)
  - [x] Authorization checks for update/delete

---

## 🚀 TÍNH NĂNG BỔ SUNG (Additional Features)

### Phase 1: Core Enhancements
- [ ] **File Upload Service**
  - [ ] Upload avatar
  - [ ] Upload product images
  - [ ] Upload POD images
  - [ ] Integration với cloud storage (AWS S3, Cloudinary, etc.)
- [ ] **Validation & Error Handling**
  - [ ] Custom validators cho phone number
  - [ ] Custom validators cho business rules
  - [ ] Cải thiện error messages
- [ ] **Logging & Monitoring**
  - [ ] Implement proper logging strategy
  - [ ] Add request/response logging
  - [ ] Performance monitoring

### Phase 2: Advanced Features
- [ ] **Search & Filter**
  - [ ] Full-text search cho products
  - [ ] Advanced filtering (price range, category, etc.)
  - [ ] Sorting options
- [ ] **Pagination**
  - [ ] Implement pagination cho all list APIs
  - [ ] Custom PageResponse DTO
- [ ] **Caching**
  - [ ] Redis integration
  - [ ] Cache frequently accessed data (products, stores)
- [ ] **Real-time Features**
  - [ ] WebSocket cho order tracking
  - [ ] Real-time notifications
- [ ] **Statistics & Reports**
  - [ ] Sales statistics (store owner)
  - [ ] Order statistics (admin)
  - [ ] Revenue reports
  - [ ] User activity reports

### Phase 3: Security & Performance
- [ ] **Security Enhancements**
  - [ ] Rate limiting
  - [ ] JWT token blacklist (Redis)
  - [ ] OTP verification cho forgot password
  - [ ] 2FA authentication
- [ ] **Performance Optimization**
  - [ ] Database indexing
  - [ ] Query optimization
  - [ ] Lazy loading vs Eager loading
  - [ ] N+1 query problem solving
- [ ] **Testing**
  - [ ] Unit tests cho Services
  - [ ] Integration tests cho Controllers
  - [ ] Test coverage > 80%

### Phase 4: DevOps & Documentation
- [ ] **API Documentation**
  - [ ] Swagger/OpenAPI integration
  - [ ] API documentation generation
  - [ ] Postman collection
- [ ] **Deployment**
  - [ ] Docker containerization
  - [ ] Docker Compose setup
  - [ ] CI/CD pipeline
  - [ ] Environment configuration (dev/staging/prod)
- [ ] **Database**
  - [ ] Database migration scripts
  - [ ] Seed data cho development
  - [ ] Backup & recovery strategy

---

## 📊 PRIORITY & TIMELINE

### Week 1-2: Core Modules
- [x] Auth Module ✅
- [x] User Module ✅
- [ ] Store Module (3-4 days)
- [ ] Product Module (3-4 days)

### Week 3-4: Business Logic
- [x] Order Module ✅ (5-6 days) - Completed with state machine
- [x] Review Module ✅ (2 days) - Completed with full features
- [ ] Payment Module (2-3 days)

### Week 5: Testing & Polish
- [ ] Unit tests
- [ ] Integration tests
- [ ] Bug fixes
- [ ] Code refactoring

### Week 6+: Advanced Features
- [ ] File upload
- [ ] Search & pagination
- [ ] Caching
- [ ] Real-time features
- [ ] Statistics & reports

---

## 🎯 NEXT IMMEDIATE TASKS (Prioritized)

1. ~~**Store Module**~~ ✅ COMPLETED

2. ~~**Product Module**~~ ✅ COMPLETED

3. ~~**Order Module**~~ ✅ COMPLETED
   - ✅ State machine: PENDING → CONFIRMED → PICKING_UP → DELIVERING → DELIVERED
   - ✅ Role-based transitions (STORE confirms, SHIPPER delivers)
   - ✅ Security: Store orders filtered by authenticated user
   - ✅ 8 REST endpoints with proper @PreAuthorize

4. ~~**Review Module**~~ ✅ COMPLETED
   - ✅ Only customers who completed orders can review
   - ✅ Rating calculation for stores (average + count)
   - ✅ ReviewRepository with all queries
   - ✅ Review DTOs (Request + Response)
   - ✅ ReviewService with full business logic
   - ✅ ReviewController with 7 REST endpoints
   - ✅ Authorization: Review owner or ADMIN can delete

5. **Payment Module** - NEXT PRIORITY
   - Integrate với MoMo payment gateway
   - Create PaymentRepository với queries
   - Create Payment DTOs
   - Implement PaymentService
   - Implement PaymentController
   - Test payment flow

---

## 📝 NOTES

- **Code Quality**: Follow SOLID principles, clean code practices
- **Security**: Always validate user permissions for each action
- **Performance**: Consider pagination for all list endpoints
- **Documentation**: Add Javadoc comments for public methods
- **Testing**: Write tests as you develop, not after
- **Git**: Commit frequently with meaningful messages

---

## 🔗 DEPENDENCIES TO ADD (If needed)

```xml
<!-- File Upload -->
<dependency>
    <groupId>commons-io</groupId>
    <artifactId>commons-io</artifactId>
    <version>2.11.0</version>
</dependency>

<!-- Caching (Redis) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>

<!-- WebSocket -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-websocket</artifactId>
</dependency>

<!-- API Documentation (Swagger) -->
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- MapStruct for DTO mapping -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
    <version>1.5.5.Final</version>
</dependency>
```

---

## 📱 FRONTEND SYNC NOTES

### ✅ APIs Ready for Frontend:
- **Auth APIs** ✅ - Frontend có thể bắt đầu code Auth screens
- **User APIs** ✅ - Frontend có thể code Profile/Settings screens  
- **Store APIs** ✅ - Frontend có thể code Store list/detail screens
- **Product APIs** ✅ - Frontend có thể code Product catalog & shopping
- **Order APIs** ✅ - Frontend có thể code Shopping cart & checkout flow
  - 8 endpoints: Create order, My orders, Order detail, Store orders, Shipper flows
  - State machine: PENDING → CONFIRMED → PICKING_UP → DELIVERING → DELIVERED
- **Review APIs** ✅ - Frontend có thể code Rating & Review screens
  - 7 endpoints: Create, Update, Delete, Get by ID, My reviews, Store reviews, Store rating
  - Business rules: Only DELIVERED orders, One review per order, 1-5 stars

### ⏳ APIs Cần Hoàn Thành Trước:
- **Payment APIs** - Cần xong trước khi Frontend integrate MoMo/ZaloPay
- **File Upload APIs** - Cần cho avatar, product images, POD photos

### 🔔 Backend Cần Bổ Sung:
- [ ] WebSocket configuration (cho real-time order tracking)
- [ ] Firebase Admin SDK setup (cho push notifications)  
- [ ] File upload service (images to cloud storage)
- [ ] API documentation với Swagger/OpenAPI
- [ ] CORS configuration cho Flutter app

---

**Last Updated**: 2026-02-13
**Progress**: 6/7 modules completed (86%) 🎉
**Completed**: Auth ✅ User ✅ Store ✅ Product ✅ Order ✅ Review ✅
**Next Focus**: Payment Module → Advanced Features (File Upload, Search, Caching, Real-time)
**Frontend Status**: Core APIs ready! Shopping, Cart, Checkout, Reviews all functional!