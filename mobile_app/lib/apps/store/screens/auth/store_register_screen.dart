import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/app_type.dart';
import '../../../../core/location/province_api.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../shared/widgets/searchable_dropdown.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_event.dart';
import '../../../../features/auth/bloc/auth_state.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../utils/store_localizations.dart';

class StoreRegisterScreen extends StatefulWidget {
  const StoreRegisterScreen({super.key});

  @override
  State<StoreRegisterScreen> createState() => _StoreRegisterScreenState();
}

class _StoreRegisterScreenState extends State<StoreRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProvinceApi _provinceApi = ProvinceApi();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<LocationItem> _provinces = const [];
  List<LocationItem> _wards = const [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;

  bool _isLoadingProvince = true;
  bool _isLoadingWard = false;
  String? _locationError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _provinceApi.getProvincesV2();
      provinces.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _isLoadingProvince = false;
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProvince = false;
        _locationError = context.storeTr('load_province_error');
      });
    }
  }

  Future<void> _loadWards(int provinceCode) async {
    setState(() {
      _isLoadingWard = true;
      _wards = const [];
      _selectedWard = null;
    });

    try {
      final wards = await _provinceApi.getWardsByProvince(provinceCode);
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _isLoadingWard = false;
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingWard = false;
        _locationError = context.storeTr('load_ward_error');
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _streetController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedProvince == null || _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.storeTr('province_ward_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fullAddress =
        '${_streetController.text.trim()}, ${_selectedWard!.name}, ${_selectedProvince!.name}';

    context.read<AuthBloc>().add(
          RegisterRequested(
            appType: AppType.store,
            userData: {
              'fullName': _fullNameController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
              'password': _passwordController.text,
              'storeName': _storeNameController.text.trim(),
              'storeAddress': fullAddress,
              'address': fullAddress,
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistering) {
          setState(() => _isLoading = true);
        }
        if (state is AuthRegistrationSuccess) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizeStoreAuthMessage(context, state.message)),
              backgroundColor: StoreTheme.primaryColor,
            ),
          );
          Navigator.pop(context);
        }
        if (state is AuthRegistrationError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizeStoreAuthMessage(context, state.message)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(context.storeTr('sign_up_store')),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  context.storeTr('store_register_title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: StoreTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.storeTr('store_register_desc'),
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: context.storeTr('full_name'),
                  hint: context.storeTr('full_name_hint'),
                  controller: _fullNameController,
                  prefixIcon: Icons.person,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return context.storeTr('full_name_required');
                    if (text.length < 2) return context.storeTr('full_name_too_short');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.storeTr('phone_number'),
                  hint: context.storeTr('phone_hint'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return context.storeTr('phone_required');
                    if (text.length < 9) return context.storeTr('phone_invalid');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.storeTr('store_name'),
                  hint: context.storeTr('store_name_example_hint'),
                  controller: _storeNameController,
                  prefixIcon: Icons.store,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return context.storeTr('store_name_required_msg');
                    if (text.length < 2) return context.storeTr('store_name_too_short_msg');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormField<LocationItem>(
                  initialValue: _selectedProvince,
                  validator: (value) {
                    if (value == null) {
                      return context.storeTr('province_required');
                    }
                    return null;
                  },
                  builder: (field) => SearchableDropdown<LocationItem>(
                    label: context.storeTr('province_city'),
                    items: _provinces,
                    selectedItem: _selectedProvince,
                    displayStringForItem: (item) => item.name,
                    onChanged: _isLoadingProvince
                        ? null
                        : (value) {
                            if (value == null) return;
                            field.didChange(value);
                            setState(() {
                              _selectedProvince = value;
                              _selectedWard = null;
                            });
                            _loadWards(value.code);
                          },
                    hintText: context.storeTr('province_city'),
                    searchHint: context.storeTr('search'),
                    emptyMessage: context.storeTr('no_results'),
                    prefixIcon: const Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                FormField<LocationItem>(
                  initialValue: _selectedWard,
                  validator: (value) {
                    if (value == null) {
                      return context.storeTr('ward_required');
                    }
                    return null;
                  },
                  builder: (field) => SearchableDropdown<LocationItem>(
                    label: context.storeTr('ward_district'),
                    items: _wards,
                    selectedItem: _selectedWard,
                    displayStringForItem: (item) => item.name,
                    onChanged: (_selectedProvince == null || _isLoadingWard)
                        ? null
                        : (value) {
                            field.didChange(value);
                            setState(() {
                              _selectedWard = value;
                            });
                          },
                    hintText: context.storeTr('ward_district'),
                    searchHint: context.storeTr('search'),
                    emptyMessage: context.storeTr('no_results'),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.storeTr('street'),
                  hint: context.storeTr('street_example_hint'),
                  controller: _streetController,
                  prefixIcon: Icons.route,
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return context.storeTr('street_required');
                    if (text.length < 3) return context.storeTr('street_too_short');
                    return null;
                  },
                ),
                if (_isLoadingProvince || _isLoadingWard) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
                if (_locationError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _locationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.storeTr('password'),
                  hint: context.storeTr('password_hint'),
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: Icons.lock,
                  validator: (v) {
                    final text = v ?? '';
                    if (text.isEmpty) return context.storeTr('password_required');
                    if (text.length < 6) return context.storeTr('password_min_6');
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: context.storeTr('confirm_password'),
                  hint: context.storeTr('confirm_password_hint'),
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if ((v ?? '').isEmpty) {
                      return context.storeTr('confirm_password_required');
                    }
                    if (v != _passwordController.text) {
                      return context.storeTr('confirm_password_mismatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StoreTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.storeTr('sign_up_store'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
