import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_event.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../features/auth/models/user_model.dart';
import 'store_login_screen.dart';
import '../home/store_home_screen.dart';

class StoreLogo extends StatelessWidget {
  final double size;

  const StoreLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/splash_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.store, size: size, color: StoreTheme.primaryColor);
      },
    );
  }
}

class StoreSplashScreen extends StatefulWidget {
  const StoreSplashScreen({super.key});

  @override
  State<StoreSplashScreen> createState() => _StoreSplashScreenState();
}

class _StoreSplashScreenState extends State<StoreSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _minSplashElapsed = false;
  AuthState? _latestAuthState;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Force a fresh auth check when app restarts (e.g. hot restart).
    context.read<AuthBloc>().add(const CheckStatusRequested());
    _startSplashTimer();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _startSplashTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _navigated) {
      return;
    }

    _minSplashElapsed = true;
    _tryNavigate();
  }

  void _onAuthStateChanged(AuthState state) {
    _latestAuthState = state;
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!mounted || _navigated || !_minSplashElapsed || _latestAuthState == null) {
      return;
    }

    final state = _latestAuthState!;

    // Wait until auth status is fully resolved.
    if (state is AuthInitial || state is AuthLoading || state is AuthTokenRefreshing) {
      return;
    }

    final isStore =
        state is AuthAuthenticated && state.user.role == UserRole.store;

    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isStore ? const StoreHomeScreen() : const StoreLoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _onAuthStateChanged(state),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Image.asset(
                    'assets/images/splash_logo.png',
                    width: 200,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  StoreTheme.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 50,
                          color: StoreTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
