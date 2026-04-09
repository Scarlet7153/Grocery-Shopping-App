part of 'order_filter_bloc.dart';

/// Events cho OrderFilterBloc
abstract class OrderFilterEvent extends Equatable {
  const OrderFilterEvent();

  @override
  List<Object?> get props => [];
}

/// Load filter hiện tại
class LoadOrderFilter extends OrderFilterEvent {
  const LoadOrderFilter();
}

/// Update filter (cập nhật một vài field)
class UpdateOrderFilter extends OrderFilterEvent {
  final OrderFilter filter;

  const UpdateOrderFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Reset filter về default
class ResetOrderFilter extends OrderFilterEvent {
  const ResetOrderFilter();
}

/// Save filter vào SharedPreferences
class SaveOrderFilter extends OrderFilterEvent {
  final OrderFilter filter;

  const SaveOrderFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Cập nhật max distance
class UpdateMaxDistance extends OrderFilterEvent {
  final double distance;

  const UpdateMaxDistance(this.distance);

  @override
  List<Object?> get props => [distance];
}

/// Cập nhật minimum earning
class UpdateMinEarning extends OrderFilterEvent {
  final double earning;

  const UpdateMinEarning(this.earning);

  @override
  List<Object?> get props => [earning];
}

/// Toggle avoid pickup
class ToggleAvoidPickup extends OrderFilterEvent {
  final bool avoid;

  const ToggleAvoidPickup(this.avoid);

  @override
  List<Object?> get props => [avoid];
}

/// Cập nhật favorite stores
class UpdateFavoriteStores extends OrderFilterEvent {
  final List<int> storeIds;

  const UpdateFavoriteStores(this.storeIds);

  @override
  List<Object?> get props => [storeIds];
}

/// Cập nhật max items per order
class UpdateMaxItems extends OrderFilterEvent {
  final int maxItems;

  const UpdateMaxItems(this.maxItems);

  @override
  List<Object?> get props => [maxItems];
}
