// lib/features/home/presentation/status_visuals.dart
//
// Presentation-only visual mappings (colour + localized label) for the home
// status enums. Kept out of the domain layer so the entities stay pure Dart.

import 'package:flutter/material.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';
import 'package:qatrah/features/home/domain/entities/schedule_entity.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

extension ScheduleStatusVisuals on ScheduleStatus {
  Color get color {
    switch (this) {
      case ScheduleStatus.scheduled:
        return const Color(0xFF5CA8D6); // Calm blue
      case ScheduleStatus.active:
        return const Color(0xFF4FAF77); // Soft green
      case ScheduleStatus.paused:
        return const Color(0xFFF5A623); // Amber
      case ScheduleStatus.completed:
        return const Color(0xFFD8DCC2); // Light alert beige
      case ScheduleStatus.cancelled:
        return const Color(0xFFF2A65A); // Light orange
    }
  }

  String toLabel(AppLocalizations l10n) => switch (this) {
    ScheduleStatus.scheduled => l10n.scheduledStatus,
    ScheduleStatus.active => l10n.activeStatus,
    ScheduleStatus.paused => l10n.pausedStatus,
    ScheduleStatus.completed => l10n.completedStatus,
    ScheduleStatus.cancelled => l10n.cancelledStatus,
  };
}

extension PumpingStatusVisuals on PumpingStatus {
  Color get color {
    switch (this) {
      case PumpingStatus.active:
        return const Color(0xFF4FAF77);
      case PumpingStatus.paused:
        return const Color(0xFFF5A623);
      case PumpingStatus.scheduled:
        return const Color(0xFF5CA8D6);
      case PumpingStatus.completed:
        return const Color(0xFF8CA0B3);
      case PumpingStatus.cancelled:
        return const Color(0xFFD4A87A);
    }
  }

  String toLabel(AppLocalizations l10n) => switch (this) {
    PumpingStatus.active => l10n.activeStatus,
    PumpingStatus.paused => l10n.pausedStatus,
    PumpingStatus.scheduled => l10n.scheduledStatus,
    PumpingStatus.completed => l10n.completedStatus,
    PumpingStatus.cancelled => l10n.cancelledStatus,
  };
}
