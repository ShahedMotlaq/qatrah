part of 'app_pin_bloc.dart';

abstract class AppPinEvent {
  const AppPinEvent();
}

/// User typed (or cleared) digits in the active field.
class AppPinDigitsChanged extends AppPinEvent {
  const AppPinDigitsChanged(this.digits);
  final String digits;
}

/// Submit current digits for the active step (varies by mode).
class AppPinSubmit extends AppPinEvent {
  const AppPinSubmit();
}

/// Setup-only: user pressed back/clear from confirmation step.
class AppPinResetEntry extends AppPinEvent {
  const AppPinResetEntry();
}

class _AppPinRestoreLock extends AppPinEvent {
  const _AppPinRestoreLock();
}
