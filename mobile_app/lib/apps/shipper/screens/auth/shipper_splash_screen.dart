import 'package:flutter/material.dart';
import '../../../../core/theme/shipper_theme.dart';
import 'shipper_login_screen.dart'; 


class ShipperSplashScreen extends StatefulWidget {
  const ShipperSplashScreen({super.key});

  @override
  State<ShipperSplashScreen> createState() => _ShipperSplashScreenState();
}

class _ShipperSplashScreenState extends State<ShipperSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToLogin();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // ✅ Enable actual navigation
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const ShipperLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ShipperTheme.primaryColor.withValues(alpha: 0.1),
              ShipperTheme.backgroundColor,
              ShipperTheme.secondaryColor.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Shipper Logo & Branding
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildShipperBranding(),
                      ),
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 1),
              
              // Animated tagline & features
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildTagline(),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Loading indicator
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: ShipperTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang khởi động...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipperBranding() => Column(
    children: [
      // Shipper Icon với Delivery Theme
      Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(70),
              boxShadow: [
                BoxShadow(
                  color: ShipperTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          // Delivery icon
          Container(
            padding: const EdgeInsets.all(28),
            child: const Icon(
              Icons.delivery_dining,
              size: 70,
              color: ShipperTheme.primaryColor,
            ),
          ),
          // Moving indicator
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 32),
      
      // App Name cho Shipper
      const Text(
        'Đi Chợ Hộ',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: ShipperTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
      
      const SizedBox(height: 8),
      
      // Shipper Subtitle
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ShipperTheme.primaryColor.withValues(alpha: 0.1),
              ShipperTheme.secondaryColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.motorcycle,
              size: 18,
              color: ShipperTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'SHIPPER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ShipperTheme.primaryColor,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildTagline() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      children: [
        Text(
          'Giao hàng thông minh, thu nhập xứng đáng',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Feature highlights
        _buildFeatureHighlights(),
      ],
    ),
  );

  Widget _buildFeatureHighlights() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(
            icon: Icons.flash_on,
            text: 'Giao nhanh',
          ),
          _buildFeatureItem(
            icon: Icons.location_on,
            text: 'Định vị GPS',
          ),
          _buildFeatureItem(
            icon: Icons.attach_money,
            text: 'Thu nhập cao',
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Tham gia mạng lưới giao hàng lớn nhất Việt Nam',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          height: 1.4,
        ),
      ),
    ],
  );

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ShipperTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: ShipperTheme.primaryColor,
          size: 24,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}