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
  final String phoneNumber;
  final String password;
  final String fullName;
  final String? address;

  const ShipperRegisterRequested({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    this.address,
  });

  @override
  List<Object?> get props => [phoneNumber, password, fullName, address];
}

class ShipperLogoutRequested extends ShipperAuthEvent {}
