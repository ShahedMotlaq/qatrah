import 'dart:developer' as dev;

import 'package:qatrah/features/settings/domain/entities/settings_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorageService {
  SettingsStorageService._privateConstructor();

  static final SettingsStorageService instance =
      SettingsStorageService._privateConstructor();

  static const String _keyDarkMode = 'settings_dark_mode';
  static const String _keySound = 'settings_sound_enabled';
  static const String _keyVibration = 'settings_vibration_enabled';
  static const String _keyNotificationsEnabled =
      'settings_notifications_enabled';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    dev.log('SettingsStorageService initialized', name: 'SETTINGS');
  }

  Future<SettingsEntity> loadSettings() async {
    await initialize();
    return SettingsEntity(
      isDarkMode: _prefs?.getBool(_keyDarkMode) ?? false,
      soundEnabled: _prefs?.getBool(_keySound) ?? true,
      vibrationEnabled: _prefs?.getBool(_keyVibration) ?? true,
    );
  }

  Future<void> setDarkMode(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyDarkMode, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await initialize();
    await _prefs?.setBool(_keySound, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyVibration, value);
  }

  Future<bool> isSoundEnabled() async {
    await initialize();
    return _prefs?.getBool(_keySound) ?? true;
  }

  Future<bool> isVibrationEnabled() async {
    await initialize();
    return _prefs?.getBool(_keyVibration) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyNotificationsEnabled, value);
  }

  Future<bool> isNotificationsEnabled() async {
    await initialize();
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> resetSettings() async {
    await initialize();
    await _prefs?.remove(_keyDarkMode);
    await _prefs?.remove(_keySound);
    await _prefs?.remove(_keyVibration);
    await _prefs?.remove(_keyNotificationsEnabled);
  }
}
