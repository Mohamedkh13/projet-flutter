import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'theme.dart';

// ----------------------------------------------------------------------------
//  Toast notifications (SnackBar based)
// ----------------------------------------------------------------------------
enum ToastType { success, warning, error }

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showToast(String message, [ToastType type = ToastType.success]) {
  final messenger = messengerKey.currentState;
  if (messenger == null) return;
  final accent = type == ToastType.success
      ? C.green
      : type == ToastType.warning
      ? C.amber
      : C.red;
  final accentText = type == ToastType.success
      ? C.greenSoft
      : type == ToastType.warning
      ? C.amberSoft
      : C.redSoft;
  final icon = type == ToastType.success
      ? Icons.check_circle_outline
      : type == ToastType.warning
      ? Icons.warning_amber_rounded
      : Icons.error_outline;
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 3500),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.md),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(R.md),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: a(C.surface, 0.9),
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: a(accent, 0.45)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: accentText, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: ts(13, C.text, w: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
