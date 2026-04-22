import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../data/notification_model.dart';
import '../data/notification_service.dart';

// ─── Events ──────────────────────────────────────────────────────────

abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
}

class MarkAllNotificationsRead extends NotificationEvent {}

class DeleteNotification extends NotificationEvent {
  final String notificationId;
  DeleteNotification(this.notificationId);
}

class ReceiveRealtimeNotification extends NotificationEvent {
  final NotificationModel notification;
  ReceiveRealtimeNotification(this.notification);
}

class UpdateUnreadCount extends NotificationEvent {
  final int count;
  UpdateUnreadCount(this.count);
}

// ─── State ───────────────────────────────────────────────────────────

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error ?? this.error,
    );
  }
}

// ─── BLoC ────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _service;

  NotificationBloc({NotificationService? service})
      : _service = service ?? NotificationService(),
        super(const NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllNotificationsRead>(_onMarkAllNotificationsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ReceiveRealtimeNotification>(_onReceiveRealtimeNotification);
    on<UpdateUnreadCount>(_onUpdateUnreadCount);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final token = await ApiClient().getAccessToken();
    if (token == null || token.isEmpty) {
      emit(state.copyWith(isLoading: false, error: null));
      return;
    }
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final notifications = await _service.getNotifications();
      final unreadCount = await _service.getUnreadCount();
      emit(state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == event.notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    ));

    // Network request
    await _service.markAsRead(event.notificationId);

    // In background, fetch actual unread count to make sure it's accurate
    final realUnreadCount = await _service.getUnreadCount();
    emit(state.copyWith(unreadCount: realUnreadCount));
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {
    // Optimistic update
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    emit(state.copyWith(notifications: updatedNotifications, unreadCount: 0));

    // Network request
    await _service.markAllAsRead();
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final deletedNotification =
          state.notifications.firstWhere((n) => n.id == event.notificationId);

      // Optimistic update
      final updatedNotifications = state.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      // Decrement unread count if it was unread
      int newUnreadCount = state.unreadCount;
      if (!deletedNotification.isRead) {
        newUnreadCount = (newUnreadCount - 1).clamp(0, 999);
      }

      emit(state.copyWith(
          notifications: updatedNotifications, unreadCount: newUnreadCount));

      // Network request
      await _service.deleteNotification(event.notificationId);
    } catch (e) {
      // Notification didn't exist in State
    }
  }

  void _onReceiveRealtimeNotification(
    ReceiveRealtimeNotification event,
    Emitter<NotificationState> emit,
  ) {
    // Check for duplicates first (using id)
    final exists =
        state.notifications.any((n) => n.id == event.notification.id);
    if (exists) return;

    // Prepend the new notification to the list
    final List<NotificationModel> newNotifications = [
      event.notification,
      ...state.notifications,
    ];

    // Accumulate tentative unread count
    int newUnreadCount = state.unreadCount;
    if (!event.notification.isRead) {
      newUnreadCount++;
    }

    emit(state.copyWith(
      notifications: newNotifications,
      unreadCount: newUnreadCount,
    ));
  }

  void _onUpdateUnreadCount(
    UpdateUnreadCount event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(unreadCount: event.count));
  }
}
