// lib/features/home/presentation/widgets/current_pumping_status_widget.dart
//
// Thin coordinator widget.  All rendering is delegated to the card widgets
// inside `pumping_status/`.  This file owns only the BlocBuilder + switch.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/cancelled_within_period_card.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/last_session_pumping_card.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/live_pumping_card.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_card_shell.dart';
import 'package:qatrah/features/home/presentation/widgets/pumping_status/pumping_section_header.dart';

/// Renders the "Current Pumping Status" section based on [PumpingDisplayMode].
///
/// Layout is always:
///   [PumpingSectionHeader]          ← always visible
///   [AnimatedSwitcher]              ← switches between the four mode cards
///
/// The BlocBuilder only rebuilds when the pumping data or location label
/// changes, keeping rebuilds narrow.
class CurrentPumpingStatusWidget extends StatelessWidget {
  const CurrentPumpingStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) =>
          prev.pumpingStatus != curr.pumpingStatus ||
          prev.monitoredAreas != curr.monitoredAreas ||
          prev.filteredLocationName != curr.filteredLocationName,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            PumpingSectionHeader(state: state),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: PumpingModeCard(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selects the correct card widget for the current [PumpingDisplayMode].
///
/// The [ValueKey] on each case ensures [AnimatedSwitcher] detects the mode
/// change and runs the transition animation.
class PumpingModeCard extends StatelessWidget {
  const PumpingModeCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.pumpingDisplayMode) {
      PumpingDisplayMode.live => LivePumpingCard(
        key: const ValueKey('live'),
        session: state.liveSession!,
      ),
      PumpingDisplayMode.cancelledWithinPeriod => CancelledWithinPeriodCard(
        key: const ValueKey('cancelled-within-period'),
        session: state.cancelledWithinWindow!,
      ),
      PumpingDisplayMode.lastSession => LastSessionPumpingCard(
        key: const ValueKey('last'),
        session: state.lastCompletedSession!,
      ),
      PumpingDisplayMode.empty => const _EmptyStatusCard(
        key: ValueKey('empty'),
      ),
    };
  }
}

/// Shown when no active, cancelled, or completed session is available.
class _EmptyStatusCard extends StatelessWidget {
  const _EmptyStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PumpingCardShell(
      accentColor: Theme.of(context).colorScheme.outline,
      child: AppEmptyState(
        message: context.l10n.noCurrentPumpingStatus,
        icon: HugeIcons.strokeRoundedDroplet,
      ),
    );
  }
}
