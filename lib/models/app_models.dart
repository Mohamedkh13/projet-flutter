// ----------------------------------------------------------------------------
//  Models
// ----------------------------------------------------------------------------
enum AuthStep { initializing, login, twoFa, dashboard }

enum DashTab { overview, resilience, security }

enum ServerStatus { unknown, optimal, warning, offline }

enum AlertType { critical, warning, info }

class EndpointProbe {
  EndpointProbe({
    required this.id,
    required this.name,
    required this.url,
    this.status = ServerStatus.unknown,
    this.latencyMs,
  });
  final String id;
  final String name;
  final String url;
  ServerStatus status;
  int? latencyMs;
}

class DeviceSample {
  const DeviceSample({
    required this.time,
    required this.cpuPercent,
    required this.memoryUsedPercent,
  });

  final DateTime time;
  final double? cpuPercent;
  final double? memoryUsedPercent;
}

class AlertItem {
  const AlertItem(this.id, this.type, this.message, this.time);
  final int id;
  final AlertType type;
  final String message;
  final String time;
}

class CacheEntry {
  const CacheEntry(this.endpoint, this.cachedAt, this.size, this.status);
  final String endpoint;
  final String cachedAt;
  final String size;
  final String status;
}

class LogEntry {
  const LogEntry(this.time, this.method, this.url, this.status, this.source);
  final String time;
  final String method;
  final String url;
  final int status;
  final String source;
}
