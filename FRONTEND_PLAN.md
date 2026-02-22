# 📋 FRONTEND DEVELOPMENT PLAN - Grocery Shopping App

## 🎯 TỔ CHỨC DỰ ÁN (Project Structure)

### Tech Stack
- **Framework**: Flutter (Cross-platform: iOS & Android)
- **Language**: Dart
- **Backend**: Spring Boot REST API with MySQL Database
- **State Management**: Bloc (flutter_bloc) / Riverpod
- **Navigation**: GoRouter / Auto Route
- **UI Library**: Material 3 / Custom Design System
- **Maps**: Google Maps Flutter
- **Camera**: Image Picker
- **HTTP Client**: Dio with Interceptors
- **Local Storage**: Hive (local cache) / Shared Preferences
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Folder Structure
```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── errors/         # Error handling
│   ├── network/        # API configuration
│   ├── theme/          # App theme & styling
│   └── utils/          # Utility functions
├── features/           # Feature-based modules
│   ├── auth/
│   │   ├── data/       # Repositories & data sources
│   │   ├── domain/     # Entities & use cases
│   │   └── presentation/ # UI & Bloc
│   ├── home/
│   ├── products/
│   ├── orders/
│   └── profile/
├── shared/
│   ├── widgets/        # Reusable widgets
│   ├── models/         # Shared models (API response models)
│   └── services/       # Shared services
└── main.dart           # App entry point
```

---

## ✅ ĐÃ HOÀN THÀNH (Completed)

### Phase 1: Project Setup & Core Infrastructure ✅ COMPLETED
- [x] **Project Initialization**
  - [x] Create Flutter project with clean architecture
  - [x] Setup folder structure theo feature-based
  - [x] Configure analysis_options.yaml (linting rules)
  - [x] Setup development environment (Android Studio/VS Code)
- [x] **Core Dependencies**
  - [x] Install navigation package (go_router)
  - [x] Setup state management (flutter_bloc)
  - [x] Install UI packages (flutter_screenutil, cached_network_image)
  - [x] Configure image picker & camera
  - [x] Setup local storage (hive for caching, shared_preferences)
  - [x] Setup JSON serialization for API models
- [x] **Base Widgets**
  - [x] LoadingWidget
  - [x] ErrorWidget (CustomErrorWidget)
  - [x] CustomButton
  - [x] CustomTextField
  - [x] CustomDialog
  - [x] SnackBar utilities


---

## 🔄 ĐANG LÀM (In Progress)


---

## 📝 CẦN LÀM (To Do)

### Module 1: Authentication & Onboarding 🔐
- [ ] **Splash Screen**
  - [ ] App logo animation
  - [ ] Check authentication status
  - [ ] Auto navigate based on user state
- [ ] **Onboarding Screens**
  - [ ] Welcome slides (3-4 screens)
  - [ ] App features introduction
  - [ ] Skip/Next navigation
- [ ] **Authentication Screens**
  - [ ] Login Screen
    - [ ] Phone number input với validation
    - [ ] Password input với show/hide
    - [ ] Remember me checkbox
    - [ ] Login button với loading state
    - [ ] Navigate to Register/Forgot Password
  - [ ] Register Screen
    - [ ] Phone number validation
    - [ ] Password confirmation
    - [ ] Full name input
    - [ ] Address input
    - [ ] Role selection (Customer/Store/Shipper)
    - [ ] Terms & Conditions checkbox
  - [ ] Forgot Password Screen
    - [ ] Phone number input
    - [ ] Send OTP functionality
    - [ ] OTP verification
    - [ ] New password setup
- [ ] **Auth State Management**
  - [ ] AuthBloc với states (Initial, Loading, Authenticated, Error)
  - [ ] Auth Repository với Dio interceptors
  - [ ] Token management (SharedPreferences)
  - [ ] Auto logout when token expires
- [ ] **Protected Routes**
  - [ ] Auth guard trong GoRouter
  - [ ] Role-based navigation

### Module 2: Customer App 🛒
#### 2.1 Home & Discovery
- [ ] **Home Screen**
  - [ ] AppBar với user avatar và location
  - [ ] Search TextField
  - [ ] Categories horizontal ListView
  - [ ] Featured stores PageView
  - [ ] Popular products GridView
  - [ ] Recent orders quick access
  - [ ] RefreshIndicator functionality
- [ ] **Search Screen**
  - [ ] Search TextField với suggestions
  - [ ] Recent searches (SharedPreferences)
  - [ ] Search filters (category, price, location)
  - [ ] Search results ListView/GridView
  - [ ] Sort options (price, rating, distance)
- [ ] **Category Screen**
  - [ ] Category ListView với icons
  - [ ] Products by category
  - [ ] Filter & sort functionality

#### 2.2 Store & Product Management
- [ ] **Store List Screen**
  - [ ] Nearby stores với distance calculation
  - [ ] Store ratings & reviews count
  - [ ] Open/Closed status indicators
  - [ ] Filter by category
  - [ ] Google Maps integration toggle
- [ ] **Store Detail Screen**
  - [ ] Store info (name, address, phone)
  - [ ] Rating & reviews section
  - [ ] Products categories TabBar
  - [ ] Products GridView với lazy loading
  - [ ] Add to cart FloatingActionButton
  - [ ] Store reviews BottomSheet
- [ ] **Product Detail Screen**
  - [ ] Product image PageView
  - [ ] Product info & description
  - [ ] Available units với prices (DropdownButton)
  - [ ] Quantity selector (Stepper widget)
  - [ ] Add to cart Button
  - [ ] Similar products ListView
- [ ] **Map Screen**
  - [ ] Google Maps widget
  - [ ] Store markers
  - [ ] Current location tracking
  - [ ] Distance calculation
  - [ ] Directions integration

#### 2.3 Shopping Cart & Checkout
- [ ] **Shopping Cart Screen**
  - [ ] Cart items ListView
  - [ ] Quantity adjustment (IconButton +/-)
  - [ ] Remove item với Dismissible
  - [ ] Store grouping (if multiple stores)
  - [ ] Total calculation
  - [ ] ElevatedButton proceed to checkout
- [ ] **Checkout Screen**
  - [ ] Delivery address selection/edit
  - [ ] Order items summary Card
  - [ ] Shipping fee calculation
  - [ ] Payment method RadioListTile
  - [ ] Special instructions TextField
  - [ ] Place order ElevatedButton
  - [ ] Order confirmation Dialog

#### 2.4 Order Management
- [ ] **Order History Screen**
  - [ ] Orders list với status badges
  - [ ] Order date & total
  - [ ] Order status timeline
  - [ ] Filter by status
  - [ ] Search orders
- [ ] **Order Detail Screen**
  - [ ] Order info & items
  - [ ] Status timeline với real-time updates
  - [ ] Store contact info
  - [ ] Shipper contact (when assigned)
  - [ ] Cancel order (if allowed)
  - [ ] Reorder functionality
- [ ] **Order Tracking Screen**
  - [ ] Real-time location tracking
  - [ ] Shipper info & contact
  - [ ] Estimated delivery time
  - [ ] Order status updates
  - [ ] POD image display (when delivered)

#### 2.5 User Profile & Settings
- [ ] **Profile Screen**
  - [ ] User avatar & name
  - [ ] Phone number
  - [ ] Address management
  - [ ] Order statistics
  - [ ] Settings navigation
- [ ] **Edit Profile Screen**
  - [ ] Change avatar (camera/gallery)
  - [ ] Update full name
  - [ ] Update address
  - [ ] Save changes
- [ ] **Change Password Screen**
  - [ ] Current password verification
  - [ ] New password input
  - [ ] Confirm password
- [ ] **Address Management Screen**
  - [ ] Saved addresses list
  - [ ] Add new address
  - [ ] Edit/Delete addresses
  - [ ] Set default address
- [ ] **Settings Screen**
  - [ ] Notifications preferences
  - [ ] Language selection
  - [ ] Theme selection (dark/light)
  - [ ] Privacy policy
  - [ ] Terms of service
  - [ ] Logout

#### 2.6 Reviews & Ratings
- [ ] **Reviews Screen**
  - [ ] My reviews list
  - [ ] Review status
  - [ ] Edit review option
- [ ] **Write Review Screen**
  - [ ] Star rating selector
  - [ ] Comment text area
  - [ ] Submit review

### Module 3: Store Owner App 🏪
#### 3.1 Store Dashboard
- [ ] **Dashboard Screen**
  - [ ] Store statistics cards
  - [ ] Today's orders count
  - [ ] Revenue overview
  - [ ] Pending orders alert
  - [ ] Quick actions (toggle status, add product)
- [ ] **Store Profile Screen**
  - [ ] Store information display
  - [ ] Edit store details
  - [ ] Open/Close toggle
  - [ ] Store hours management
  - [ ] Store photos gallery

#### 3.2 Product Management
- [ ] **Products Screen**
  - [ ] Products list với status
  - [ ] Search products
  - [ ] Filter by category/status
  - [ ] Add product button
  - [ ] Bulk actions
- [ ] **Add Product Screen**
  - [ ] Product name & description
  - [ ] Category selection
  - [ ] Product image upload
  - [ ] Units & pricing table
  - [ ] Stock quantity input
  - [ ] Save product
- [ ] **Edit Product Screen**
  - [ ] Edit product details
  - [ ] Manage units & prices
  - [ ] Update stock quantity
  - [ ] Toggle availability
  - [ ] Delete product

#### 3.3 Order Management
- [ ] **Orders Screen**
  - [ ] Orders list với status filtering
  - [ ] Order cards với customer info
  - [ ] Action buttons (confirm/cancel)
  - [ ] Search orders
- [ ] **Order Detail Screen**
  - [ ] Order items detail
  - [ ] Customer information
  - [ ] Delivery address
  - [ ] Order actions
  - [ ] Contact customer

#### 3.4 Analytics & Reports
- [ ] **Analytics Screen**
  - [ ] Sales statistics charts
  - [ ] Popular products
  - [ ] Customer insights
  - [ ] Revenue trends
- [ ] **Reviews Management Screen**
  - [ ] Store reviews list
  - [ ] Average rating display
  - [ ] Respond to reviews

### Module 4: Shipper App 🚚
#### 4.1 Shipper Dashboard
- [ ] **Dashboard Screen**
  - [ ] Available orders map
  - [ ] Earnings today
  - [ ] Completed deliveries
  - [ ] Online/Offline toggle
- [ ] **Available Orders Screen**
  - [ ] Pending orders list
  - [ ] Order details preview
  - [ ] Distance & estimated time
  - [ ] Accept order button
  - [ ] Filter by distance/payment

#### 4.2 Order Fulfillment
- [ ] **Active Order Screen**
  - [ ] Order details
  - [ ] Store location & customer address
  - [ ] Navigation to store
  - [ ] Pick up confirmation
  - [ ] Navigation to customer
- [ ] **Delivery Screen**
  - [ ] Customer contact info
  - [ ] Delivery address
  - [ ] Order items checklist
  - [ ] POD photo capture
  - [ ] Complete delivery
  - [ ] Payment collection (COD)

#### 4.3 Earnings & History
- [ ] **Earnings Screen**
  - [ ] Daily/Weekly/Monthly earnings
  - [ ] Payment history
  - [ ] Pending payments
- [ ] **Delivery History Screen**
  - [ ] Completed orders list
  - [ ] Order details view
  - [ ] Earnings per order

### Module 5: Admin App 👨‍💼
#### 5.1 Dashboard & Analytics
- [ ] **Admin Dashboard**
  - [ ] System statistics
  - [ ] Users count by role
  - [ ] Total orders & revenue
  - [ ] Recent activities
- [ ] **Analytics Screen**
  - [ ] Revenue analytics
  - [ ] User growth charts
  - [ ] Order statistics
  - [ ] Popular categories

#### 5.2 User Management
- [ ] **Users Management Screen**
  - [ ] Users list với filtering
  - [ ] Search users
  - [ ] User details view
  - [ ] Ban/Unban users
  - [ ] Role management

#### 5.3 Content Management
- [ ] **Categories Management Screen**
  - [ ] Categories list
  - [ ] Add/Edit/Delete categories
  - [ ] Category icons management
- [ ] **Reports Screen**
  - [ ] System reports
  - [ ] Export functionality
  - [ ] Data analytics

### Module 6: Shared Widgets & Features 🔧
#### 6.1 Real-time Features
- [ ] **WebSocket Integration**
  - [ ] Order status updates
  - [ ] Real-time chat (customer-shipper)
  - [ ] Push notifications
- [ ] **Push Notifications**
  - [ ] FCM integration
  - [ ] Order updates
  - [ ] Promotional notifications
  - [ ] System announcements

#### 6.2 Location Services
- [ ] **Location Services**
  - [ ] GPS tracking cho shippers (Geolocator)
  - [ ] Distance calculation
  - [ ] Address geocoding
  - [ ] Google Maps integration

#### 6.3 Payment Integration
- [ ] **Payment Gateway**
  - [ ] MoMo SDK integration
  - [ ] COD handling
  - [ ] Payment verification
  - [ ] Refund processing

#### 6.4 Flutter-Specific Features
- [ ] **State Management Architecture**
  - [ ] BlocProvider setup
  - [ ] Repository pattern implementation
  - [ ] Dependency injection (get_it)
  - [ ] Event-driven architecture
- [ ] **API Response Handling**
  - [ ] JSON serialization/deserialization
  - [ ] Model classes với @JsonSerializable
  - [ ] Nested object handling
  - [ ] Date/DateTime parsing (ISO 8601)
  - [ ] Error response handling
- [ ] **Custom Widgets**
  - [ ] Reusable form widgets
  - [ ] Custom animations (AnimationController)
  - [ ] Shimmer loading effects
  - [ ] Pull-to-refresh indicators
- [ ] **Platform-Specific Code**
  - [ ] iOS/Android specific implementations
  - [ ] Platform channels (if needed)
  - [ ] Native plugins integration
- [ ] **Performance Optimization**
  - [ ] Image caching strategy
  - [ ] ListView optimization (cho large datasets)
  - [ ] Memory management
  - [ ] Build optimization
  - [ ] Pagination handling for REST API

---

## 🚀 TÍNH NĂNG BỔ SUNG (Advanced Features)

### Phase 1: Enhanced User Experience
- [ ] **Offline Support**
  - [ ] Cached data when offline
  - [ ] Sync when back online
  - [ ] Offline indicators
- [ ] **Dark Mode**
  - [ ] Theme switching
  - [ ] Persistent theme preference
- [ ] **Multi-language Support**
  - [ ] Vietnamese/English
  - [ ] Dynamic language switching
  - [ ] RTL support

### Phase 2: Business Intelligence
- [ ] **AI-Powered Features**
  - [ ] Product recommendations based on user history
  - [ ] Smart search suggestions
  - [ ] Demand forecasting cho stores từ historical data
- [ ] **Advanced Analytics**
  - [ ] User behavior tracking
  - [ ] A/B testing framework
  - [ ] Performance monitoring
- [ ] **Advanced Backend Features**
  - [ ] Real-time updates via WebSocket
  - [ ] Location-based search and filtering
  - [ ] Full-text product search
  - [ ] Server-sent events for notifications

### Phase 3: Social Features
- [ ] **Social Integration**
  - [ ] Share products/stores
  - [ ] Social login
  - [ ] Referral system
- [ ] **Community Features**
  - [ ] User reviews photos
  - [ ] Store following
  - [ ] Wishlist sharing

### Phase 4: Enterprise Features
- [ ] **Multi-tenant Support**
  - [ ] White-label solutions
  - [ ] Custom branding
- [ ] **Advanced Integrations**
  - [ ] ERP systems
  - [ ] Accounting software
  - [ ] Inventory management

---

## 📊 DEVELOPMENT PHASES & TIMELINE

### Phase 1: Foundation (Weeks 1-3)
- [x] Project setup & dependencies
- [ ] Authentication module
- [ ] Basic navigation structure
- [ ] Core UI components
- [ ] State management setup

### Phase 2: Core Customer App (Weeks 4-8)
- [ ] Home & discovery screens
- [ ] Store & product browsing
- [ ] Shopping cart & checkout
- [ ] Basic order management
- [ ] User profile management

### Phase 3: Store Owner App (Weeks 9-12)
- [ ] Store dashboard
- [ ] Product management
- [ ] Order processing
- [ ] Basic analytics

### Phase 4: Shipper App (Weeks 13-15)
- [ ] Shipper dashboard
- [ ] Order fulfillment flow
- [ ] GPS tracking
- [ ] Earnings management

### Phase 5: Admin Panel (Weeks 16-17)
- [ ] System administration
- [ ] User management
- [ ] Content management
- [ ] Reports & analytics

### Phase 6: Polish & Advanced Features (Weeks 18-20)
- [ ] Real-time features
- [ ] Push notifications
- [ ] Performance optimization
- [ ] Testing & bug fixes

---

## 🎯 TECHNICAL REQUIREMENTS

### Performance
- [ ] **App Performance**
  - [ ] Launch time < 3 seconds
  - [ ] Smooth 60fps animations
  - [ ] Memory optimization (đặc biệt với large JSON documents)
  - [ ] Battery usage optimization
- [ ] **Network Optimization**
  - [ ] API response caching với Hive
  - [ ] Image lazy loading
  - [ ] Offline-first approach với local cache
  - [ ] Network error handling
  - [ ] Pagination strategy for REST API
  - [ ] JSON parsing optimization for nested objects

### Security
- [ ] **Data Security**
  - [ ] Secure token storage
  - [ ] API encryption
  - [ ] Input validation
  - [ ] XSS protection
- [ ] **User Privacy**
  - [ ] Location permission handling
  - [ ] Data anonymization
  - [ ] GDPR compliance
  - [ ] Privacy policy implementation

### Testing Strategy
- [ ] **Unit Testing**
  - [ ] Utility functions
  - [ ] Bloc states & events
  - [ ] API services (Dio with REST API)
  - [ ] Repository classes với caching
  - [ ] JSON serialization/deserialization
- [ ] **Widget Testing**
  - [ ] Individual widgets
  - [ ] Screen widgets với mock API data
  - [ ] Integration flows
- [ ] **Integration Testing**
  - [ ] Critical user journeys
  - [ ] Cross-platform testing (iOS/Android)
  - [ ] Performance testing với large datasets
  - [ ] API integration testing

---

## 🛠 TOOLS & SETUP

### Development Tools
```yaml
# pubspec.yaml - Core dependencies
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Navigation
  go_router: ^12.1.3
  
  # Networking & JSON
  dio: ^5.3.2
  json_annotation: ^4.8.1
  
  # UI & Utils
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  
  # Date/Time handling
  intl: ^0.19.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  flutter_lints: ^3.0.0
  bloc_test: ^9.1.5
  hive_generator: ^2.0.1  # For Hive TypeAdapters
```

### Build Configuration
- [ ] **Environment Setup**
  - [ ] Development environment (dev)
  - [ ] Staging environment (staging)
  - [ ] Production environment (prod)
- [ ] **Build Automation**
  - [ ] Flutter CI/CD với GitHub Actions
  - [ ] Automated testing pipeline
  - [ ] App distribution (Firebase App Distribution)

---

## 📱 UI/UX DESIGN PRINCIPLES

### Design System
- [ ] **Color Palette**
  - Primary: Green (Colors.green)
  - Secondary: Orange (Colors.orange)
  - Success: Colors.green
  - Warning: Colors.orange
  - Error: Colors.red
  - Background: Colors.grey.shade50
- [ ] **Typography**
  - Headers: TextStyle(fontWeight: FontWeight.bold)
  - Body: TextStyle(fontWeight: FontWeight.normal)
  - Caption: TextStyle(fontWeight: FontWeight.w300)
- [ ] **Spacing & Layout**
  - 8dp grid system (SizedBox, Padding)
  - Consistent margins/paddings
  - Responsive design với ScreenUtil

### User Experience
- [ ] **Navigation Patterns**
  - BottomNavigationBar cho main sections
  - Navigator.push cho details
  - Drawer cho secondary actions
- [ ] **Interaction Design**
  - Loading states (CircularProgressIndicator)
  - Empty states với clear CTAs
  - Error states với retry options
  - Success feedback (SnackBar animations)

---

## 📋 CHECKLISTS

### Pre-Development Checklist
- [ ] Figma designs completed
- [ ] API documentation reviewed
- [ ] Development environment setup
- [ ] Team roles defined
- [ ] Project timeline confirmed

### Pre-Release Checklist
- [ ] All features tested
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] App store assets prepared
- [ ] Release notes written

### Post-Release Checklist
- [ ] App store monitoring
- [ ] User feedback collection
- [ ] Crash reporting setup
- [ ] Analytics implementation
- [ ] Support documentation

---

## 🔄 AGILE WORKFLOW

### Sprint Structure (2-week sprints)
- **Sprint Planning**: Define scope & tasks
- **Daily Standups**: Progress & blockers
- **Sprint Review**: Demo & feedback
- **Retrospective**: Process improvement

### Quality Assurance
- [ ] Code review process
- [ ] Testing checklist per feature
- [ ] Performance monitoring
- [ ] User acceptance testing

---

## 🔧 FLUTTER DEVELOPMENT BEST PRACTICES

### Code Organization
- [ ] **Clean Architecture**
  - [ ] Separation of concerns (Data, Domain, Presentation)
  - [ ] Dependency inversion principle
  - [ ] Single responsibility principle
- [ ] **Feature-First Structure**
  - [ ] Group by features, not by layers
  - [ ] Shared components in common folder
  - [ ] Clear import/export strategies

### State Management with Bloc
```dart
// Example Bloc structure
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        phoneNumber: event.phoneNumber,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }
}
```

### API Integration with Dio
```dart
// Example API service
class ApiService {
  final Dio _dio;
  
  ApiService() : _dio = Dio() {
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggerInterceptor());
  }
  
  Future<User> login(String phoneNumber, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'phoneNumber': phoneNumber,
      'password': password,
    });
    return User.fromJson(response.data);
  }
}
```

### Custom Widgets Examples
```dart
// Reusable loading button
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const LoadingButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}
```

### Navigation Setup with GoRouter
```dart
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductsScreen(),
        ),
        // ... more routes
      ],
    ),
  ],
);
```

### API Response Models Examples
```dart
// User model from MySQL backend
@JsonSerializable()
class User {
  final int id; // MySQL BIGINT/Long
  final String phoneNumber;
  final String fullName;
  final String? avatarUrl;
  final String address;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.avatarUrl,
    required this.address,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// Product model with nested units from MySQL
@JsonSerializable()
class Product {
  final int id;
  final int storeId;
  final int? categoryId;
  final String name;
  final String? description;
  final String? imageUrl;
  final ProductStatus status;
  final List<ProductUnit> units; // Nested objects from backend

  Product({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.status,
    required this.units,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

// Product unit nested object
@JsonSerializable()
class ProductUnit {
  final int id;
  final String unitName;
  final double price;
  final int stockQuantity;

  ProductUnit({
    required this.id,
    required this.unitName,
    required this.price,
    required this.stockQuantity,
  });

  factory ProductUnit.fromJson(Map<String, dynamic> json) => _$ProductUnitFromJson(json);
  Map<String, dynamic> toJson() => _$ProductUnitToJson(this);
}

// Order model with nested items
@JsonSerializable()
class Order {
  final int id;
  final int customerId;
  final int storeId;
  final int? shipperId;
  final OrderStatus status;
  final double totalAmount;
  final double shippingFee;
  final String deliveryAddress;
  final List<OrderItem> items; // Nested objects
  final String? podImageUrl;
  final String? cancelReason;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.storeId,
    this.shipperId,
    required this.status,
    required this.totalAmount,
    required this.shippingFee,
    required this.deliveryAddress,
    required this.items,
    this.podImageUrl,
    this.cancelReason,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```

### API Service for Spring Boot REST API
```dart
// API service for Spring Boot backend
class ApiService {
  final Dio _dio;
  
  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = 'http://localhost:8080/api';
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggerInterceptor());
  }
  
  // GET with pagination (Spring Boot page/size params)
  Future<PaginatedResponse<Product>> getProducts({
    int page = 0, // Spring Boot starts from 0
    int size = 20,
    String? category,
    String? search,
  }) async {
    final response = await _dio.get('/products', queryParameters: {
      'page': page,
      'size': size,
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    });
    
    return PaginatedResponse<Product>.fromJson(
      response.data,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }
  
  // POST to create product
  Future<ApiResponse<Product>> createProduct(CreateProductRequest request) async {
    final response = await _dio.post('/products', data: request.toJson());
    return ApiResponse<Product>.fromJson(
      response.data,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );
  }
  
  // GET stores list
  Future<ApiResponse<List<Store>>> getAllStores() async {
    final response = await _dio.get('/stores');
    return ApiResponse<List<Store>>.fromJson(
      response.data,
      (json) => (json as List)
          .map((item) => Store.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Standard API Response wrapper (matches backend ApiResponse.java)
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errorCode: json['errorCode'] as String?,
    );
  }

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => {
    'success': success,
    'message': message,
    'data': data != null ? toJsonT(data as T) : null,
    'errorCode': errorCode,
  };
}
```

### Hive Local Storage for API Response Caching
```dart
// Hive adapters for local caching
@HiveType(typeId: 0)
class CachedUser extends HiveObject {
  @HiveField(0)
  late int id; // MySQL Long/BIGINT
  
  @HiveField(1)
  late String phoneNumber;
  
  @HiveField(2)
  late String fullName;
  
  @HiveField(3)
  String? avatarUrl;
  
  @HiveField(4)
  late String address;
  
  @HiveField(5)
  late DateTime lastUpdated;
  
  CachedUser();
  
  CachedUser.fromUser(User user) {
    id = user.id;
    phoneNumber = user.phoneNumber;
    fullName = user.fullName;
    avatarUrl = user.avatarUrl;
    address = user.address;
    lastUpdated = DateTime.now();
  }
  
  User toUser() {
    return User(
      id: id,
      phoneNumber: phoneNumber,
      fullName: fullName,
      avatarUrl: avatarUrl,
      address: address,
      role: UserRole.customer, // Default
      status: UserStatus.active,
      createdAt: DateTime.now(),
      updatedAt: lastUpdated,
    );
  }
}

// Repository with REST API + Hive caching
class ProductRepository {
  final ApiService _apiService;
  final Box<CachedProduct> _productBox;
  
  ProductRepository(this._apiService, this._productBox);
  
  Future<List<Product>> getProducts({
    bool forceRefresh = false,
    String? category,
  }) async {
    if (!forceRefresh) {
      // Try to get from local cache first
      final cachedProducts = _productBox.values
          .where((cached) => 
              category == null || cached.categoryId.toString() == category)
          .toList();
      
      if (cachedProducts.isNotEmpty) {
        return cachedProducts.map((cached) => cached.toProduct()).toList();
      }
    }
    
    // Fetch from API
    final response = await _apiService.getProducts(category: category);
    
    // Check if API call was successful
    if (response.success && response.data != null) {
      // Cache the results
      for (final product in response.data!) {
        final cached = CachedProduct.fromProduct(product);
        await _productBox.put(product.id, cached);
      }
      
      return response.data!;
    }
    
    return [];
  }
}
```

---

**Last Updated**: 2026-02-12
**Project Status**: Ready to start development (synced with MySQL backend)
**Current Phase**: Phase 1 - Foundation
**Backend**: Spring Boot + MySQL (Auth & User modules completed)
**Team Size**: 2-3 developers
**Timeline**: 20 weeks (5 months)
**Platform**: Flutter (iOS & Android)

---

## 🔄 BACKEND SYNC STATUS

### ✅ Backend APIs Ready:
- **Auth Module** - Login, Register, Logout, Refresh Token, Get Current User
- **User Module** - Profile, Update, Change Password, Admin Management
- **Store Module** - CRUD, Toggle Status, Search (90% complete)

### ⏳ Backend In Development:
- **Product Module** - Pending (Controllers & Services needed)
- **Order Module** - Pending (Most complex, core business logic)
- **Payment Module** - Pending (MoMo integration needed)
- **Review Module** - Pending

### 📝 Frontend Development Strategy:
- **Week 1-3**: Setup + Auth screens (can start now)
- **Week 4+**: Wait for Product APIs before building product screens
- **Week 7+**: Wait for Order APIs before building order flow
- Coordinate closely with backend team on API contracts
