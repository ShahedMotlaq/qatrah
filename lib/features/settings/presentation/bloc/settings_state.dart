class SettingsState {
  const SettingsState({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  final bool isDarkMode;
  final bool soundEnabled;
  final bool vibrationEnabled;

  SettingsState copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
