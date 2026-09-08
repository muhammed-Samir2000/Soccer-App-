import 'notification_setting.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationSetting>> getSettings();

  Future<void> updateSetting(NotificationSetting setting);
}
