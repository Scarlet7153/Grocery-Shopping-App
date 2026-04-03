import 'package:flutter/material.dart';
import '../../../../core/theme/admin_theme.dart';
// Đã xóa dòng import 'admin_login_screen.dart' bị sai

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

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

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // ✅ Fix: Sử dụng Route đã định nghĩa trong main_admin.dart
      // Điều này giúp gọi đúng LoginScreen dùng chung với UserRole.admin
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AdminTheme.primaryColor.withValues(alpha: 0.05),
              AdminTheme.backgroundColor,
              AdminTheme.secondaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated Admin Logo & Branding
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAdminBranding(),
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
                          color: AdminTheme.primaryColor,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đang khởi tạo Admin Panel...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

  Widget _buildAdminBranding() => Column(
    children: [
      // Admin Crown Icon với Premium Design
      Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(80),
              boxShadow: [
                BoxShadow(
                  color: AdminTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Main container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AdminTheme.backgroundColor,
                ],
              ),
              borderRadius: BorderRadius.circular(70),
              border: Border.all(
                color: AdminTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 70,
              color: AdminTheme.primaryColor,
            ),
          ),
          // Crown overlay
          Positioned(
            top: 15,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.diamond,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 32),
      
      // App Name cho Admin
      const Text(
        'Đi Chợ Hộ',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
      
      const SizedBox(height: 8),
      
      // Admin Subtitle với Premium Design
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AdminTheme.primaryColor.withValues(alpha: 0.1),
              AdminTheme.secondaryColor.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AdminTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              size: 18,
              color: AdminTheme.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'ADMIN PANEL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AdminTheme.primaryColor,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildTagline() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      children: [
        Text(
          'Quản lý và điều hành hệ thống',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Admin feature highlights
        _buildAdminFeatures(),
        
        const SizedBox(height: 20),
        Text(
          'Trung tâm điều khiển toàn diện cho nền tảng Đi Chợ Hộ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  );

  Widget _buildAdminFeatures() => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(
            icon: Icons.dashboard,
            text: 'Dashboard',
            color: AdminTheme.primaryColor,
          ),
          _buildFeatureItem(
            icon: Icons.analytics,
            text: 'Analytics',
            color: Colors.green,
          ),
          _buildFeatureItem(
            icon: Icons.security,
            text: 'Security',
            color: Colors.orange,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(
            icon: Icons.people,
            text: 'Users',
            color: Colors.blue,
          ),
          _buildFeatureItem(
            icon: Icons.store,
            text: 'Stores',
            color: Colors.teal,
          ),
          _buildFeatureItem(
            icon: Icons.settings,
            text: 'Settings',
            color: Colors.grey[700]!,
          ),
        ],
      ),
    ],
  );

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
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