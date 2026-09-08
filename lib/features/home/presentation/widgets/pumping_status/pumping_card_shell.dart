// lib/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// White card body that sits beneath the section header.
///
/// A 2.5-pt coloured stripe runs along the top edge, using [accentColor], to
/// give instant visual feedback about the pumping category without relying on
/// colour alone (accessibility-friendly).
class PumpingCardShell extends StatelessWidget {
  const PumpingCardShell({
    required this.accentColor,
    required this.child,
    super.key,
  });

  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(top: BorderSide(color: accentColor, width: 2.5)),
      ),
      padding: EdgeInsets.all(14.w),
      child: child,
    );
  }
}
