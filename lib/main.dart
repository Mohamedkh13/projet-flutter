import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'core/toast.dart';
import 'models/app_models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/two_fa_screen.dart';
import 'state/app_controller.dart';

// ============================================================================
//  Flutter Advanced Network Admin & Monitoring Suite
//  Native Flutter / Dart port (no third-party packages required).
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AdminApp());
}

// ----------------------------------------------------------------------------
//  Root app
// ----------------------------------------------------------------------------
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final AppController controller = AppController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _screenFor(AuthStep step) {
    switch (step) {
      case AuthStep.login:
        return LoginScreen(controller: controller);
      case AuthStep.twoFa:
        return TwoFaScreen(controller: controller);
      case AuthStep.dashboard:
        return DashboardScreen(controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Advanced Network Admin & Monitoring Suite',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.dark(),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final step = controller.step;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey<AuthStep>(step),
              child: _screenFor(step),
            ),
          );
        },
      ),
    );
  }
}
