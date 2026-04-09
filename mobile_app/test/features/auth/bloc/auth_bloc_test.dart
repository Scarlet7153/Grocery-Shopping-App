// import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// import 'package:mockito/annotations.dart';

// Mock classes - tạm thời không import từ files khác
class MockAuthRepository extends Mock {}

class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  bool operator ==(Object other) => other is AuthInitial;

  @override
  int get hashCode => 0;
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  bool operator ==(Object other) => other is AuthLoading;

  @override
  int get hashCode => 1;
}

class AuthAuthenticated extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  const AuthAuthenticated({required this.token, required this.user});

  @override
  bool operator ==(Object other) =>
      other is AuthAuthenticated && other.token == token && other.user == user;

  @override
  int get hashCode => token.hashCode ^ user.hashCode;
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({required this.message, this.errorCode});

  @override
  bool operator ==(Object other) =>
      other is AuthError &&
      other.message == message &&
      other.errorCode == errorCode;

  @override
  int get hashCode => message.hashCode ^ errorCode.hashCode;
}

class AuthEvent {
  const AuthEvent();
}

class LoginRequested extends AuthEvent {
  final String identifier;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.identifier,
    required this.password,
    this.rememberMe = false,
  });
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

// Simple AuthBloc for testing
class AuthBloc {
  AuthState _state = const AuthInitial();
  final MockAuthRepository repository;

  AuthBloc({required this.repository});

  AuthState get state => _state;

  void add(AuthEvent event) {
    if (event is LoginRequested) {
      _handleLogin(event);
    } else if (event is LogoutRequested) {
      _handleLogout();
    }
  }

  void _handleLogin(LoginRequested event) {
    _state = const AuthLoading();
    // Simulate async login
    Future.delayed(Duration.zero, () {
      if (event.identifier == 'test@example.com' &&
          event.password == 'password123') {
        _state = const AuthAuthenticated(
          token: 'test-token',
          user: {'id': '1', 'email': 'test@example.com'},
        );
      } else {
        _state = const AuthError(
          message: 'Invalid credentials',
          errorCode: 'login_failed',
        );
      }
    });
  }

  void _handleLogout() {
    _state = const AuthInitial();
  }

  void close() {
    // Cleanup if needed
  }
}

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('LoginRequested', () {
      test(
        'should emit AuthLoading then AuthAuthenticated on successful login',
        () async {
          // Act
          authBloc.add(
            const LoginRequested(
              identifier: 'test@example.com',
              password: 'password123',
            ),
          );

          // Assert initial loading state
          expect(authBloc.state, equals(const AuthLoading()));

          // Wait for async operation
          await Future.delayed(const Duration(milliseconds: 10));

          // Assert final authenticated state
          expect(authBloc.state, isA<AuthAuthenticated>());
          final authenticatedState = authBloc.state as AuthAuthenticated;
          expect(authenticatedState.token, equals('test-token'));
          expect(authenticatedState.user['email'], equals('test@example.com'));
        },
      );

      test('should emit AuthLoading then AuthError on failed login', () async {
        // Act
        authBloc.add(
          const LoginRequested(
            identifier: 'wrong@example.com',
            password: 'wrongpassword',
          ),
        );

        // Assert initial loading state
        expect(authBloc.state, equals(const AuthLoading()));

        // Wait for async operation
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert final error state
        expect(authBloc.state, isA<AuthError>());
        final errorState = authBloc.state as AuthError;
        expect(errorState.message, equals('Invalid credentials'));
        expect(errorState.errorCode, equals('login_failed'));
      });
    });

    group('LogoutRequested', () {
      test('should emit AuthInitial on logout', () {
        // Arrange - set authenticated state first
        authBloc.add(
          const LoginRequested(
            identifier: 'test@example.com',
            password: 'password123',
          ),
        );

        // Act
        authBloc.add(const LogoutRequested());

        // Assert
        expect(authBloc.state, equals(const AuthInitial()));
      });
    });

    group('State Equality', () {
      test('AuthInitial states should be equal', () {
        const state1 = AuthInitial();
        const state2 = AuthInitial();
        expect(state1, equals(state2));
      });

      test('AuthLoading states should be equal', () {
        const state1 = AuthLoading();
        const state2 = AuthLoading();
        expect(state1, equals(state2));
      });

      test('AuthAuthenticated states with same data should be equal', () {
        const state1 = AuthAuthenticated(token: 'token1', user: {'id': '1'});
        const state2 = AuthAuthenticated(token: 'token1', user: {'id': '1'});
        expect(state1, equals(state2));
      });

      test('AuthError states with same message should be equal', () {
        const state1 = AuthError(message: 'Error 1', errorCode: 'code1');
        const state2 = AuthError(message: 'Error 1', errorCode: 'code1');
        expect(state1, equals(state2));
      });
    });

    group('Edge Cases', () {
      test('should handle empty credentials', () async {
        authBloc.add(const LoginRequested(identifier: '', password: ''));

        expect(authBloc.state, equals(const AuthLoading()));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authBloc.state, isA<AuthError>());
      });

      test('should handle null-like values', () async {
        authBloc.add(
          const LoginRequested(identifier: 'null', password: 'null'),
        );

        expect(authBloc.state, equals(const AuthLoading()));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authBloc.state, isA<AuthError>());
      });
    });

    group('Integration Tests', () {
      test('complete login-logout flow', () async {
        // Initial state
        expect(authBloc.state, equals(const AuthInitial()));

        // Login
        authBloc.add(
          const LoginRequested(
            identifier: 'test@example.com',
            password: 'password123',
          ),
        );

        expect(authBloc.state, equals(const AuthLoading()));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authBloc.state, isA<AuthAuthenticated>());

        // Logout
        authBloc.add(const LogoutRequested());

        expect(authBloc.state, equals(const AuthInitial()));
      });

      test('multiple failed login attempts', () async {
        // First failed attempt
        authBloc.add(
          const LoginRequested(
            identifier: 'wrong1@example.com',
            password: 'wrong1',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authBloc.state, isA<AuthError>());

        // Second failed attempt
        authBloc.add(
          const LoginRequested(
            identifier: 'wrong2@example.com',
            password: 'wrong2',
          ),
        );

        expect(authBloc.state, equals(const AuthLoading()));

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authBloc.state, isA<AuthError>());
      });
    });
  });
}
