part of 'shipper_auth_bloc.dart';

abstract class ShipperAuthState extends Equatable {
  const ShipperAuthState();

  @override
  List<Object?> get props => [];
}

class ShipperAuthInitial extends ShipperAuthState {}

class ShipperAuthLoading extends ShipperAuthState {}

class ShipperAuthAuthenticated extends ShipperAuthState {}

class ShipperAuthError extends ShipperAuthState {
  final String message;
  const ShipperAuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
