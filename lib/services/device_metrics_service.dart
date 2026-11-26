import 'package:flutter/services.dart';

class DeviceMetricsService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.projet/device_metrics',
  );

  Future<Map<String, Object?>?> read() async {
    try {
      return await _channel.invokeMapMethod<String, Object?>('read');
    } on MissingPluginException {
      return null;
    }
  }
}
