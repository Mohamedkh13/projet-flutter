// ----------------------------------------------------------------------------
//  Models
// ----------------------------------------------------------------------------
enum AuthStep { login, twoFa, dashboard }

enum DashTab { overview, resilience, security }

enum ServerStatus { optimal, warning, offline }

enum AlertType { critical, warning, info }

class ServerNode {
  ServerNode({
    required this.id,
    required this.name,
    required this.status,
    required this.cpu,
    required this.ram,
    required this.ping,
    required this.ip,
  });
  final String id;
  final String name;
  final ServerStatus status;
  int cpu;
  int ram;
  final String ping;
  final String ip;
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

class Vulnerability {
  Vulnerability({
    required this.id,
    required this.title,
    required this.severity,
    required this.description,
    required this.fixed,
  });
  final String id;
  final String title;
  final String severity;
  final String description;
  bool fixed;
}

class JwtState {
  JwtState({
    required this.token,
    required this.status,
    required this.refreshToken,
  });
  final String token;
  String status;
  final String refreshToken;
}
