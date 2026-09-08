/// Settings entity containing all user preferences
class SettingsEntity {
  const SettingsEntity({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  final bool isDarkMode;
  final bool soundEnabled;
  final bool vibrationEnabled;

  SettingsEntity copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsEntity(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
