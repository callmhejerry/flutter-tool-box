class NotificationChannelConfig {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String androidIconName; // e.g. '@mipmap/ic_launcher'

  const NotificationChannelConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.androidIconName = '@mipmap/ic_launcher',
  });
}
