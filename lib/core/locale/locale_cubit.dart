import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';

/// Cubit for the app locale state.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._secureStorage) : super(const Locale('ar'));

  final SecureStorage _secureStorage;

  /// Arabic is the only supported locale.
  static const List<Locale> supportedLocales = [
    Locale('ar'),
  ];

  /// Keep the app pinned to Arabic.
  Future<void> setLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      await _secureStorage.setLocalizedValue(locale.languageCode);
      emit(locale);
    }
  }

  /// Check if current locale is Arabic.
  bool get isArabic => state.languageCode == 'ar';
}
