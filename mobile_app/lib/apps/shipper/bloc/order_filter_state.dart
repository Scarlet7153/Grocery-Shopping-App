part of 'order_filter_bloc.dart';

/// States cho OrderFilterBloc
abstract class OrderFilterState extends Equatable {
  const OrderFilterState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo
class OrderFilterInitial extends OrderFilterState {
  const OrderFilterInitial();
}

/// Đang load filter
class OrderFilterLoading extends OrderFilterState {
  const OrderFilterLoading();
}

/// Filter đã được load thành công
class OrderFilterLoaded extends OrderFilterState {
  final OrderFilter filter;

  const OrderFilterLoaded(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Có lỗi khi load filter
class OrderFilterError extends OrderFilterState {
  final String message;

  const OrderFilterError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Filter đã được save thành công
class OrderFilterSaved extends OrderFilterState {
  final OrderFilter filter;

  const OrderFilterSaved(this.filter);

  @override
  List<Object?> get props => [filter];
}
