import '../domain/notification_repository.dart';
import '../domain/notification_setting.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository()
    : _settings = <NotificationSetting>[
        const NotificationSetting(
          id: 'new-booking',
          title: 'حجز جديد',
          description: 'تنبيه للإدارة عند تسجيل حجز جديد.',
          enabled: true,
        ),
        const NotificationSetting(
          id: 'player-reminder',
          title: 'تذكير اللاعب',
          description: 'تذكير قبل الموعد بـ24 ساعة.',
          enabled: true,
        ),
        const NotificationSetting(
          id: 'empty-slots',
          title: 'الساعات الفاضية',
          description: 'ملخص يومي لساعات بكرة الفاضية.',
          enabled: false,
        ),
      ];

  final List<NotificationSetting> _settings;

  @override
  Future<List<NotificationSetting>> getSettings() async =>
      List.unmodifiable(_settings);

  @override
  Future<void> updateSetting(NotificationSetting setting) async {
    final int index = _settings.indexWhere(
      (NotificationSetting item) => item.id == setting.id,
    );
    if (index == -1) {
      throw StateError('Notification setting not found');
    }
    _settings[index] = setting;
  }
}
