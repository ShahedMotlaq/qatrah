// lib/features/home/presentation/widgets/pumping_status/pumping_section_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';

const _kHeaderBg = Color(0xFF1B4D3E);

/// The forest-green header strip that is always visible regardless of which
/// pumping display mode is active.
///
/// Shows the section title on the leading side and a location chip on the
/// trailing side.  Both strings come exclusively from [l10n].
class PumpingSectionHeader extends StatelessWidget {
  const PumpingSectionHeader({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final locationLabel = state.monitoredAreas.isNotEmpty
        ? l10n.watchedAreasCount(state.monitoredAreas.length)
        : (state.filteredLocationName ?? l10n.defaultLocation);

    return Container(
      decoration: const BoxDecoration(
        color: _kHeaderBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedDroplet,
            color: theme.colorScheme.secondary,
          ),
          Expanded(
            child: Text(
              l10n.currentPumpingStatus,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          _LocationChip(label: locationLabel, theme: theme),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 180.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontSize: 11.sp,
        ),
      ),
    );
  }
}
