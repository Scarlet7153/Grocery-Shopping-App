part of 'shipper_profile_bloc.dart';

enum ProfileStatus { initial, loading, loaded, error, success }

class ShipperProfileState {
  final ProfileStatus status;
  final UserProfile? userProfile;
  final String? errorMessage;
  final bool isPasswordChanged;

  const ShipperProfileState({
    this.status = ProfileStatus.initial,
    this.userProfile,
    this.errorMessage,
    this.isPasswordChanged = false,
  });

  ShipperProfileState copyWith({
    ProfileStatus? status,
    UserProfile? userProfile,
    String? errorMessage,
    bool? isPasswordChanged,
  }) {
    return ShipperProfileState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage ?? this.errorMessage,
      isPasswordChanged: isPasswordChanged ?? this.isPasswordChanged,
    );
  }

  bool get isLoading => status == ProfileStatus.loading;
  bool get isLoaded => status == ProfileStatus.loaded;
  bool get isError => status == ProfileStatus.error;
  bool get isSuccess => status == ProfileStatus.success;
}
