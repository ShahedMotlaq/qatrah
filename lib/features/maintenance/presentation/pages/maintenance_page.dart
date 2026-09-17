import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({
    required this.onRetry,
    this.message,
    this.retryAfterSeconds,
    super.key,
  });

  final VoidCallback onRetry;

  /// Server-supplied explanation. Falls back to the bundled text when the
  /// server sent none.
  final String? message;

  /// When the server says how long to wait, the retry button counts down
  /// instead of letting the user hammer a server that is still down.
  final int? retryAfterSeconds;

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _remaining = widget.retryAfterSeconds ?? 0;
    if (_remaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remaining--);
        if (_remaining <= 0) {
          _timer?.cancel();
          widget.onRetry();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = widget.message?.trim();
    final waiting = _remaining > 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.maintenanceTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message == null || message.isEmpty
                      ? l10n.maintenanceMessage
                      : message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: waiting ? '${l10n.retry} ($_remaining)' : l10n.retry,
                  isDisabled: waiting,
                  onPressed: waiting ? null : widget.onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
