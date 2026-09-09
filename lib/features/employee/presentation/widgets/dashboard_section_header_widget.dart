import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class DashboardSectionHeaderWidget extends StatelessWidget {
  const DashboardSectionHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        // Full radius: the filter panel that used to sit under this header
        // now lives in the AppBar sheet, so the header is the whole card.
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedWaterPump,
            color: theme.colorScheme.secondary,
          ),
          Text(
            l10n.schedules,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
