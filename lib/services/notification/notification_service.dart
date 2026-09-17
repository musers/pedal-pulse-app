abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getDeviceToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}
