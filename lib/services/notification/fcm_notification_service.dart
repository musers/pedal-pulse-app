import 'notification_service.dart';

class FcmNotificationService implements NotificationService {
  String? _cachedToken;
  final Set<String> _subscribedTopics = {};

  @override
  Future<void> initialize() async {
    // Initialized FCM push listener
    _cachedToken = 'fcm_token_demo_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String?> getDeviceToken() async {
    return _cachedToken ?? 'fcm_token_sample_device_blr_01';
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    _subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _subscribedTopics.remove(topic);
  }
}
