import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';

class DummyAreaDetailsPage extends StatelessWidget {
  const DummyAreaDetailsPage({required this.areaName, super.key});

  final String areaName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: QatrahAppBarWidget(
        title: Text(areaName),
      ),
      body: Center(
        child: Text(
          '${l10n.areaDetailsTitle(areaName)}\n${l10n.areaDetailsSubtitle}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ),
    );
  }
}
