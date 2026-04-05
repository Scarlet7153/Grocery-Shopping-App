part of 'shipper_auth_bloc.dart';

abstract class ShipperAuthEvent extends Equatable {
  const ShipperAuthEvent();

  @override
  List<Object?> get props => [];
}

class ShipperLoginRequested extends ShipperAuthEvent {
  final String phone;
  final String password;

  const ShipperLoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class ShipperRegisterRequested extends ShipperAuthEvent {
  final Map<String, dynamic> registrationInfo;
  const ShipperRegisterRequested({required this.registrationInfo});

  @override
  List<Object?> get props => [registrationInfo];
}

class ShipperLogoutRequested extends ShipperAuthEvent {}
