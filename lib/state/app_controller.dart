import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/toast.dart';
import '../models/app_models.dart';
import '../services/device_metrics_service.dart';
import '../services/firebase_data_service.dart';

// ----------------------------------------------------------------------------
//  Application state (ChangeNotifier) - Real Network & Device Telemetry
// ----------------------------------------------------------------------------
class AppController extends ChangeNotifier {
  AppController() {
    _authSub = _auth.authStateChanges().listen(_handleAuthState);
  }

  AuthStep step = AuthStep.initializing;
  String username = '';
  bool pinGateLoading = false;
  bool pinIsConfigured = false;
  bool pinIsLocked = false;
  String? pinGateError;
  String? pinEntryError;
  DashTab activeTab = DashTab.overview;
  bool isOnline = false;
  bool isConnectivityKnown = false;
  bool internetReachable = false;
  bool hasProbedNetwork = false;
  String connectionType = 'Checking';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Future<void>? _googleSignInInitialization;
  final FirebaseDataService _firebaseData = FirebaseDataService();
  StreamSubscription<User?>? _authSub;
  String? _pinGateUserId;
  Future<void>? _pinGateTask;
  int _pinGateGeneration = 0;

  static const int _maxPinAttempts = 5;

  String _pinStorageKey(String uid) => 'personal_pin.$uid';
  String _pinFailuresKey(String uid) => 'personal_pin_failures.$uid';

  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final DeviceMetricsService _deviceMetrics = DeviceMetricsService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _deviceSampleTimer;
  Timer? _networkProbeTimer;
  bool _telemetryStarted = false;
  bool _refreshInProgress = false;
  bool _hasReportedMetricsError = false;
  String deviceName = 'Reading device…';
  String deviceOs = 'Reading system…';
  String localIpAddress = 'Unavailable';
  double? appCpuPercent;
  double? appMemoryMb;
  double? memoryUsedPercent;
  double? totalMemoryMb;
  int? batteryLevel;
  String batteryState = 'Unavailable';
  bool? isPhysicalDevice;
  int? networkLatencyMs;
  DateTime? lastUpdatedAt;
  DateTime? tokenExpiresAt;

  final List<EndpointProbe> endpointProbes = [
    EndpointProbe(
      id: 'google',
      name: 'Google connectivity',
      url: 'https://www.google.com/generate_204',
    ),
    EndpointProbe(
      id: 'cloudflare',
      name: 'Cloudflare',
      url: 'https://www.cloudflare.com/cdn-cgi/trace',
    ),
    EndpointProbe(
      id: 'github',
      name: 'GitHub API',
      url: 'https://api.github.com/zen',
    ),
  ];

  final List<DeviceSample> deviceSamples = [];
  final List<AlertItem> alerts = [];
  final List<CacheEntry> cacheData = [];

  final List<LogEntry> interceptorLogs = [];

  String get authProvider {
    final providers = _auth.currentUser?.providerData ?? [];
    final provider = providers.isEmpty ? null : providers.first.providerId;
    return switch (provider) {
      'google.com' => 'Google',
      null => 'Not signed in',
      _ => provider,
    };
  }

  static String _now() {
    final n = DateTime.now();
    String t(int v) => v.toString().padLeft(2, '0');
    return '${t(n.hour)}:${t(n.minute)}:${t(n.second)}';
  }

  // --------------------------------------------------------------------------
  //  Real Device & Network Initialization
  // --------------------------------------------------------------------------
  void _handleAuthState(User? user) {
    if (user == null) {
      _pinGateGeneration++;
      _pinGateUserId = null;
      _pinGateTask = null;
      pinGateLoading = false;
      pinIsConfigured = false;
      pinIsLocked = false;
      pinGateError = null;
      pinEntryError = null;
      if (step != AuthStep.login) {
        step = AuthStep.login;
        username = '';
        unawaited(_stopRealTelemetry());
        notifyListeners();
      }
      return;
    }

    username = user.email ?? user.uid;
    if (_pinGateUserId != user.uid ||
        step == AuthStep.initializing ||
        step == AuthStep.login) {
      unawaited(_preparePinGate(user));
    } else {
      notifyListeners();
    }
  }

  Future<void> _preparePinGate(User user) {
    if (_pinGateUserId == user.uid && _pinGateTask != null) {
      return _pinGateTask!;
    }

    _pinGateUserId = user.uid;
    step = AuthStep.twoFa;
    pinGateLoading = true;
    pinIsConfigured = false;
    pinIsLocked = false;
    pinGateError = null;
    pinEntryError = null;
    notifyListeners();

    final generation = ++_pinGateGeneration;
    final task = _loadPinGateState(user.uid, generation);
    _pinGateTask = task;
    return task;
  }

  Future<void> _loadPinGateState(String uid, int generation) async {
    try {
      final isConfigured = await _secureStorage.containsKey(
        key: _pinStorageKey(uid),
      );
      final failures =
          int.tryParse(
            await _secureStorage.read(key: _pinFailuresKey(uid)) ?? '0',
          ) ??
          0;
      if (generation == _pinGateGeneration) {
        pinIsConfigured = isConfigured;
        pinIsLocked = failures >= _maxPinAttempts;
      }
    } on PlatformException catch (error) {
      if (generation == _pinGateGeneration) {
        pinGateError =
            'Secure PIN storage is unavailable: ${error.message ?? error.code}';
        showToast(pinGateError!, ToastType.error);
      }
    } on MissingPluginException catch (error) {
      if (generation == _pinGateGeneration) {
        pinGateError = 'Secure PIN storage is unavailable: $error';
        showToast(pinGateError!, ToastType.error);
      }
    } finally {
      if (generation == _pinGateGeneration) {
        pinGateLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryPinGateCheck() async {
    final user = _auth.currentUser;
    if (user == null) {
      step = AuthStep.login;
      notifyListeners();
      return;
    }
    _pinGateTask = null;
    await _preparePinGate(user);
  }

  void clearPinEntryError() {
    if (pinEntryError != null) {
      pinEntryError = null;
      notifyListeners();
    }
  }

  void lockForBackground() {
    if (step == AuthStep.dashboard) {
      pinEntryError = null;
      step = AuthStep.twoFa;
      unawaited(_stopRealTelemetry());
      notifyListeners();
    }
  }

  Map<String, dynamic> _dashboardToMap() => {
    'logs': interceptorLogs
        .map(
          (entry) => {
            'time': entry.time,
            'method': entry.method,
            'url': entry.url,
            'status': entry.status,
            'source': entry.source,
          },
        )
        .toList(),
  };

  Future<void> _persistDashboard() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firebaseData.saveDashboard(user.uid, _dashboardToMap());
    } catch (e) {
      showToast(
        'Could not sync dashboard data with Firebase: $e',
        ToastType.warning,
      );
    }
  }

  Future<void> _restoreDashboard(String uid) async {
    try {
      final data = await _firebaseData.loadDashboard(uid);
      if (data == null) return;

      final savedLogs = data['logs'];
      if (savedLogs is List) {
        interceptorLogs
          ..clear()
          ..addAll(
            savedLogs.whereType<Map>().map(
              (item) => LogEntry(
                (item['time'] ?? '').toString(),
                (item['method'] ?? '').toString(),
                (item['url'] ?? '').toString(),
                (item['status'] as num?)?.toInt() ?? 0,
                (item['source'] ?? '').toString(),
              ),
            ),
          );
      }
      notifyListeners();
    } catch (e) {
      showToast(
        'Could not load dashboard data from Firebase: $e',
        ToastType.warning,
      );
    }
  }

  Future<void> _initRealTelemetry() async {
    if (_telemetryStarted) return;
    _telemetryStarted = true;

    await _loadRealDeviceInfo();
    await _loadLocalIpAddress();

    try {
      final initialResults = await _connectivity.checkConnectivity();
      _handleConnectivityUpdate(initialResults, notifyToast: false);
      _connectivitySub = _connectivity.onConnectivityChanged.listen(
        (results) => _handleConnectivityUpdate(results, notifyToast: true),
        onError: (Object error) {
          showToast('Network state updates failed: $error', ToastType.warning);
        },
      );
    } catch (error) {
      isConnectivityKnown = false;
      connectionType = 'Unavailable';
      showToast('Could not read network state: $error', ToastType.warning);
    }

    await triggerRefresh(silent: true);
    _deviceSampleTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_refreshDeviceMetrics()),
    );
    _networkProbeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(triggerRefresh(silent: true)),
    );
  }

  void _handleConnectivityUpdate(
    List<ConnectivityResult> results, {
    required bool notifyToast,
  }) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    final changed = isConnectivityKnown && isOnline != connected;
    isConnectivityKnown = true;
    isOnline = connected;
    connectionType = connected
        ? results
              .firstWhere((r) => r != ConnectivityResult.none)
              .name
              .toUpperCase()
        : 'NONE';

    if (changed) {
      final message = connected
          ? 'Network connection restored ($connectionType).'
          : 'Network connection lost.';
      alerts.insert(
        0,
        AlertItem(
          alerts.length + 1,
          connected ? AlertType.info : AlertType.warning,
          message,
          _now(),
        ),
      );
      if (alerts.length > 20) alerts.removeLast();
    }

    if (!connected) {
      internetReachable = false;
      hasProbedNetwork = true;
      networkLatencyMs = null;
      for (final probe in endpointProbes) {
        probe
          ..status = ServerStatus.offline
          ..latencyMs = null;
      }
    } else if (changed) {
      hasProbedNetwork = false;
      unawaited(_loadLocalIpAddress());
      unawaited(triggerRefresh(silent: true));
    }

    if (notifyToast && changed) {
      showToast(
        connected
            ? 'Connected to $connectionType.'
            : 'Network disconnected. Live endpoint checks paused.',
        connected ? ToastType.success : ToastType.warning,
      );
    }
    notifyListeners();
  }

  Future<void> _loadRealDeviceInfo() async {
    try {
      if (kIsWeb) {
        final web = await _deviceInfo.webBrowserInfo;
        deviceName = '${web.browserName.name.toUpperCase()} Web Client';
        deviceOs = web.platform ?? 'Web';
      } else if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        deviceName = '${android.manufacturer} ${android.model}';
        deviceOs =
            'Android ${android.version.release} (SDK ${android.version.sdkInt})';
        isPhysicalDevice = android.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        deviceName = ios.name;
        deviceOs = '${ios.systemName} ${ios.systemVersion}';
        isPhysicalDevice = ios.isPhysicalDevice;
      } else if (Platform.isWindows) {
        final win = await _deviceInfo.windowsInfo;
        deviceName = win.computerName;
        deviceOs =
            'Windows (${win.numberOfCores} cores, '
            '${(win.systemMemoryInMegabytes / 1024).toStringAsFixed(1)} GB RAM)';
      } else if (Platform.isMacOS) {
        final mac = await _deviceInfo.macOsInfo;
        deviceName = mac.computerName;
        deviceOs = 'macOS ${mac.osRelease}';
      } else if (Platform.isLinux) {
        final linux = await _deviceInfo.linuxInfo;
        deviceName = linux.prettyName;
        deviceOs = linux.version ?? 'Linux';
      }
      notifyListeners();
    } catch (error) {
      deviceName = 'Unavailable';
      deviceOs = 'Unavailable';
      showToast('Could not read device details: $error', ToastType.warning);
    }
  }

  Future<void> _loadLocalIpAddress() async {
    if (kIsWeb) {
      localIpAddress = 'Not exposed by browser';
      return;
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final address = interfaces
          .expand((interface) => interface.addresses)
          .where((address) => !address.isLoopback && !address.isLinkLocal)
          .firstOrNull;
      localIpAddress = address?.address ?? 'Unavailable';
      notifyListeners();
    } on SocketException catch (error) {
      localIpAddress = 'Unavailable';
      showToast(
        'Could not read the local IP address: $error',
        ToastType.warning,
      );
    }
  }

  Future<void> _refreshDeviceMetrics() async {
    try {
      final nativeMetrics = await _deviceMetrics.read();
      appCpuPercent = (nativeMetrics?['cpuPercent'] as num?)?.toDouble();
      memoryUsedPercent = (nativeMetrics?['memoryUsedPercent'] as num?)
          ?.toDouble();
      totalMemoryMb = (nativeMetrics?['totalMemoryMb'] as num?)?.toDouble();
      batteryLevel = (nativeMetrics?['batteryLevel'] as num?)?.toInt();
      batteryState =
          (nativeMetrics?['batteryState'] as String?) ?? 'Unavailable';

      if (kIsWeb) {
        appMemoryMb = null;
      } else {
        appMemoryMb =
            (nativeMetrics?['appMemoryMb'] as num?)?.toDouble() ??
            ProcessInfo.currentRss / (1024 * 1024);
      }

      if (appCpuPercent != null || memoryUsedPercent != null) {
        deviceSamples.add(
          DeviceSample(
            time: DateTime.now(),
            cpuPercent: appCpuPercent,
            memoryUsedPercent: memoryUsedPercent,
          ),
        );
        if (deviceSamples.length > 12) deviceSamples.removeAt(0);
      }
      lastUpdatedAt = DateTime.now();
      _hasReportedMetricsError = false;
      notifyListeners();
    } on PlatformException catch (error) {
      appCpuPercent = null;
      memoryUsedPercent = null;
      batteryLevel = null;
      batteryState = 'Unavailable';
      if (!_hasReportedMetricsError) {
        showToast(
          'Could not read device metrics: ${error.message ?? error.code}',
          ToastType.warning,
        );
        _hasReportedMetricsError = true;
      }
      notifyListeners();
    }
  }

  Future<int?> _measureRealEndpointLatency(String url) async {
    final sw = Stopwatch()..start();
    try {
      await _dio.get<void>(
        url,
        options: Options(validateStatus: (status) => status != null),
      );
      sw.stop();
      return sw.elapsedMilliseconds;
    } on DioException {
      sw.stop();
      return null;
    }
  }

  Future<void> _stopRealTelemetry() async {
    _deviceSampleTimer?.cancel();
    _networkProbeTimer?.cancel();
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _telemetryStarted = false;
  }

  @override
  void dispose() {
    _deviceSampleTimer?.cancel();
    _networkProbeTimer?.cancel();
    _connectivitySub?.cancel();
    _authSub?.cancel();
    _dio.close();
    super.dispose();
  }

  // --- Firebase Authentication ---
  Future<void> loginWithGoogle() async {
    try {
      _googleSignInInitialization ??= _googleSignIn.initialize();
      await _googleSignInInitialization;

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        showToast(
          'Google sign-in did not return an ID token. Please try again.',
          ToastType.error,
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        showToast(
          'Google sign-in succeeded but no Firebase user was returned.',
          ToastType.error,
        );
        return;
      }
      try {
        await _secureStorage.delete(key: _pinFailuresKey(user.uid));
      } on PlatformException catch (error) {
        showToast(
          'Could not reset PIN lockout state: ${error.message ?? error.code}',
          ToastType.error,
        );
      } on MissingPluginException catch (error) {
        showToast('Secure PIN storage is unavailable: $error', ToastType.error);
      }
      _pinGateTask = null;
      await _preparePinGate(user);
      showToast('Google account verified. Complete your personal PIN step.');
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        showToast(
          e.description ?? 'Google sign-in failed (${e.code.name}).',
          ToastType.error,
        );
      }
    } on FirebaseAuthException catch (e) {
      showToast(
        e.message ?? 'Google sign-in failed (${e.code}).',
        ToastType.error,
      );
    } catch (e) {
      showToast('Google sign-in failed: $e', ToastType.error);
    }
  }

  Future<void> registerWithEmailPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      username = email.trim();
      showToast('Firebase account created successfully.');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      showToast(
        e.message ?? 'Account creation failed (${e.code}).',
        ToastType.error,
      );
    }
  }

  void backToLogin() {
    step = AuthStep.login;
    notifyListeners();
  }

  Future<void> configurePin(String pin, String confirmation) async {
    if (!_isValidPin(pin) || !_isValidPin(confirmation)) {
      pinEntryError = 'Choose a 4-digit PIN.';
      notifyListeners();
      return;
    }
    if (pin != confirmation) {
      pinEntryError = 'The PINs do not match. Try confirming again.';
      showToast(pinEntryError!, ToastType.error);
      notifyListeners();
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      step = AuthStep.login;
      showToast(
        'Your Firebase session has expired. Sign in again.',
        ToastType.error,
      );
      notifyListeners();
      return;
    }

    try {
      final existingPin = await _secureStorage.read(
        key: _pinStorageKey(user.uid),
      );
      if (existingPin != null) {
        pinIsConfigured = true;
        pinEntryError = 'A PIN is already set. Enter it to unlock.';
        notifyListeners();
        return;
      }
      await _secureStorage.write(key: _pinStorageKey(user.uid), value: pin);
      await _secureStorage.delete(key: _pinFailuresKey(user.uid));
      pinIsConfigured = true;
      pinIsLocked = false;
      pinEntryError = null;
    } on PlatformException catch (error) {
      pinEntryError =
          'Could not securely save the PIN: ${error.message ?? error.code}';
      showToast(pinEntryError!, ToastType.error);
      notifyListeners();
      return;
    } on MissingPluginException catch (error) {
      pinEntryError = 'Secure PIN storage is unavailable: $error';
      showToast(pinEntryError!, ToastType.error);
      notifyListeners();
      return;
    }

    await _launchDashboard(user);
  }

  Future<void> verify2FA(String enteredPin) async {
    if (!_isValidPin(enteredPin)) {
      pinEntryError = 'Enter all 4 digits of your PIN.';
      notifyListeners();
      return;
    }
    if (pinGateError != null || pinGateLoading) return;

    final user = _auth.currentUser;
    if (user == null) {
      step = AuthStep.login;
      showToast(
        'Your Firebase session has expired. Sign in again.',
        ToastType.error,
      );
      notifyListeners();
      return;
    }
    if (pinIsLocked) {
      pinEntryError = 'Too many attempts. Sign in with Google to try again.';
      notifyListeners();
      return;
    }

    try {
      final storedPin = await _secureStorage.read(
        key: _pinStorageKey(user.uid),
      );
      if (storedPin == null) {
        pinIsConfigured = false;
        pinEntryError = 'No PIN is set. Create one to continue.';
        notifyListeners();
        return;
      }
      if (enteredPin != storedPin) {
        final failures =
            int.tryParse(
              await _secureStorage.read(key: _pinFailuresKey(user.uid)) ?? '0',
            ) ??
            0;
        final updatedFailures = failures + 1;
        await _secureStorage.write(
          key: _pinFailuresKey(user.uid),
          value: updatedFailures.toString(),
        );
        pinIsLocked = updatedFailures >= _maxPinAttempts;
        pinEntryError = pinIsLocked
            ? 'Too many attempts. Sign in with Google to try again.'
            : 'Incorrect PIN. ${_maxPinAttempts - updatedFailures} attempts remaining.';
        showToast(pinEntryError!, ToastType.error);
        notifyListeners();
        return;
      }

      await _secureStorage.delete(key: _pinFailuresKey(user.uid));
      pinIsLocked = false;
      pinEntryError = null;
    } on PlatformException catch (error) {
      pinGateError =
          'Secure PIN storage is unavailable: ${error.message ?? error.code}';
      showToast(pinGateError!, ToastType.error);
      notifyListeners();
      return;
    } on MissingPluginException catch (error) {
      pinGateError = 'Secure PIN storage is unavailable: $error';
      showToast(pinGateError!, ToastType.error);
      notifyListeners();
      return;
    }

    await _launchDashboard(user);
  }

  bool _isValidPin(String value) =>
      value.length == 4 && RegExp(r'^\d{4}$').hasMatch(value);

  Future<void> _launchDashboard(User user) async {
    await _restoreDashboard(user.uid);
    step = AuthStep.dashboard;
    unawaited(_initRealTelemetry());
    unawaited(refreshSecurityStatus());
    showToast('PIN verified. Dashboard loaded.');
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      if (_googleSignInInitialization != null) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      showToast('Sign-out failed: $e', ToastType.error);
      return;
    }
    step = AuthStep.login;
    await _stopRealTelemetry();
    cachedApiResponse = null;
    cacheData.clear();
    interceptorLogs.clear();
    alerts.clear();
    deviceSamples.clear();
    for (final probe in endpointProbes) {
      probe
        ..status = ServerStatus.unknown
        ..latencyMs = null;
    }
    username = '';
    _pinGateUserId = null;
    _pinGateTask = null;
    activeTab = DashTab.overview;
    showToast('Session terminated successfully.', ToastType.warning);
    notifyListeners();
  }

  // --- Dashboard ---
  void setTab(DashTab tab) {
    activeTab = tab;
    notifyListeners();
    unawaited(_persistDashboard());
  }

  Future<void> triggerRefresh({bool silent = false}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    if (!silent) showToast('Refreshing device and network measurements…');

    try {
      await _refreshDeviceMetrics();
      if (!isOnline) {
        internetReachable = false;
        hasProbedNetwork = true;
        networkLatencyMs = null;
        for (final probe in endpointProbes) {
          probe
            ..status = ServerStatus.offline
            ..latencyMs = null;
        }
      } else {
        final latencies = await Future.wait(
          endpointProbes.map((probe) => _measureRealEndpointLatency(probe.url)),
        );
        for (var i = 0; i < endpointProbes.length; i++) {
          final latency = latencies[i];
          endpointProbes[i]
            ..latencyMs = latency
            ..status = latency == null
                ? ServerStatus.offline
                : (latency > 1000
                      ? ServerStatus.warning
                      : ServerStatus.optimal);
        }
        final reachableLatencies = latencies.whereType<int>().toList();
        internetReachable = reachableLatencies.isNotEmpty;
        hasProbedNetwork = true;
        networkLatencyMs = reachableLatencies.isEmpty
            ? null
            : (reachableLatencies.reduce((a, b) => a + b) /
                      reachableLatencies.length)
                  .round();
      }

      lastUpdatedAt = DateTime.now();
      notifyListeners();
      unawaited(_persistDashboard());
    } finally {
      _refreshInProgress = false;
    }
  }

  // --- Resilience (real request and in-memory response cache) ---
  String? cachedApiResponse;

  Future<void> performNetworkRequest() async {
    final time = _now();
    const endpoint = 'https://api.github.com/zen';

    if (!isOnline) {
      final hasCachedResponse = cachedApiResponse != null;
      interceptorLogs.insert(
        0,
        LogEntry(
          time,
          'GET',
          '/zen',
          hasCachedResponse ? 200 : 503,
          hasCachedResponse ? 'In-memory response cache' : 'No cached response',
        ),
      );
      showToast(
        hasCachedResponse
            ? 'Network is offline; the last real response is available in the local cache.'
            : 'Network is offline and no response has been cached yet.',
        hasCachedResponse ? ToastType.warning : ToastType.error,
      );
      notifyListeners();
      unawaited(_persistDashboard());
      return;
    }

    final sw = Stopwatch()..start();
    try {
      final response = await _dio.get<String>(endpoint);
      sw.stop();
      final status = response.statusCode ?? 200;
      final bytes = (response.data?.length ?? 0);
      cachedApiResponse = response.data;

      interceptorLogs.insert(
        0,
        LogEntry(
          time,
          'GET',
          '/zen (${sw.elapsedMilliseconds}ms)',
          status,
          'Device network ($bytes chars)',
        ),
      );

      cacheData.removeWhere((entry) => entry.endpoint == endpoint);
      cacheData.insert(
        0,
        CacheEntry(endpoint, time, '$bytes chars', 'Cached in memory'),
      );
      if (cacheData.length > 10) cacheData.removeLast();

      showToast(
        'Real API request successful: HTTP $status (${sw.elapsedMilliseconds}ms)',
      );
    } on DioException catch (e) {
      sw.stop();
      final code = e.response?.statusCode ?? 503;
      final hasCachedResponse = cachedApiResponse != null;
      interceptorLogs.insert(
        0,
        LogEntry(
          time,
          'GET',
          '/zen',
          code,
          hasCachedResponse ? 'Network error; cache retained' : 'Network error',
        ),
      );
      showToast(
        hasCachedResponse
            ? 'Request failed (${e.type.name}); the previous response remains cached.'
            : 'Request failed (${e.type.name}); no cached response is available.',
        ToastType.warning,
      );
    }
    notifyListeners();
    unawaited(_persistDashboard());
  }

  void clearLogs() {
    interceptorLogs.clear();
    showToast('Interceptor logs cleared.');
    notifyListeners();
    unawaited(_persistDashboard());
  }

  bool get isReleaseBuild => kReleaseMode;
  bool get supportsNativeDeviceMetrics => !kIsWeb && Platform.isAndroid;

  Future<void> refreshSecurityStatus() async {
    await _loadRealDeviceInfo();
    final user = _auth.currentUser;
    if (user == null) {
      tokenExpiresAt = null;
    } else {
      try {
        final tokenResult = await user.getIdTokenResult();
        tokenExpiresAt = tokenResult.expirationTime;
      } on FirebaseAuthException catch (error) {
        showToast(
          'Could not read Firebase session status: ${error.message ?? error.code}',
          ToastType.warning,
        );
      }
    }
    notifyListeners();
  }
}
