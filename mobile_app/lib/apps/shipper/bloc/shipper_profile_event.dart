part of 'shipper_profile_bloc.dart';

abstract class ShipperProfileEvent {
  const ShipperProfileEvent();
}

class LoadUserProfile extends ShipperProfileEvent {
  const LoadUserProfile();
}

class UpdateUserProfile extends ShipperProfileEvent {
  final String fullName;
  final String? address;
  final String? avatarUrl;

  const UpdateUserProfile({
    required this.fullName,
    this.address,
    this.avatarUrl,
  });
}

class ChangePassword extends ShipperProfileEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePassword({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}

class ClearProfile extends ShipperProfileEvent {
  const ClearProfile();
}
