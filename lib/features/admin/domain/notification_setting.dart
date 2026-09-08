class NotificationSetting {
  const NotificationSetting({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
  });

  final String id;
  final String title;
  final String description;
  final bool enabled;

  NotificationSetting copyWith({bool? enabled}) => NotificationSetting(
    id: id,
    title: title,
    description: description,
    enabled: enabled ?? this.enabled,
  );
}
