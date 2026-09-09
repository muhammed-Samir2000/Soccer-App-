import 'in_app_notification.dart';
import 'notification_setting.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationSetting>> getSettings();

  Future<void> updateSetting(NotificationSetting setting);

  Future<List<InAppNotification>> getNotificationsFor(
    NotificationAudience audience,
  );

  Stream<List<InAppNotification>> watchNotificationsFor(
    NotificationAudience audience,
  );

  Future<void> markAsRead(String notificationId);
}
