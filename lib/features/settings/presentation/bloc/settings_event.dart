import 'package:qatrah/features/settings/domain/entities/settings_entity.dart';

abstract class SettingsEvent {}

class ToggleDarkModeEvent extends SettingsEvent {
  ToggleDarkModeEvent(this.value);
  final bool value;
}

class ToggleSoundEvent extends SettingsEvent {
  ToggleSoundEvent(this.value);
  final bool value;
}

class ToggleVibrationEvent extends SettingsEvent {
  ToggleVibrationEvent(this.value);
  final bool value;
}

class LoadSettingsEvent extends SettingsEvent {
  LoadSettingsEvent(this.settings);
  final SettingsEntity settings;
}
