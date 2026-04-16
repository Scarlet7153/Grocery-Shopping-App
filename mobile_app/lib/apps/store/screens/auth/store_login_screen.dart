import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/app_type.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_event.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../features/auth/models/user_model.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../utils/store_localizations.dart';
import 'store_register_screen.dart';

class StoreLoginScreen extends StatefulWidget {
  const StoreLoginScreen({super.key});
  @override
  State<StoreLoginScreen> createState() => _StoreLoginScreenState();
}

class _StoreLoginScreenState extends State<StoreLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) setState(() => _isLoading = true);
        if (state is AuthAuthenticated) {
          setState(() => _isLoading = false);
          if (state.user.role == UserRole.store) {
            Navigator.pushReplacementNamed(context, '/store/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.storeTr('store_no_permission')),
                backgroundColor: Colors.red));
          }
        }
        if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(localizeStoreAuthMessage(context, state.message)),
              backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: StoreTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.store,
                        size: 48, color: StoreTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                    Text(context.storeTr('store_login_title'),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: StoreTheme.primaryColor)),
                  const SizedBox(height: 8),
                    Text(context.storeTr('store_login_subtitle'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  CustomTextField(
                      label: context.storeTr('phone_number'),
                      hint: context.storeTr('phone_hint'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                      validator: (v) =>
                        v == null || v.isEmpty
                          ? context.storeTr('phone_required')
                          : null),
                  const SizedBox(height: 20),
                  CustomTextField(
                      label: context.storeTr('password'),
                      hint: context.storeTr('password_hint'),
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: Icons.lock,
                      validator: (v) =>
                        v == null || v.isEmpty
                          ? context.storeTr('password_required')
                          : null),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(LoginRequested(
                                    identifier: _phoneController.text,
                                    password: _passwordController.text,
                                    appType: AppType.store));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: StoreTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(context.storeTr('sign_in'),
                            style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.storeTr('store_no_account'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoreRegisterScreen(),
                            ),
                          );
                        },
                        child: Text(context.storeTr('store_register_now')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
