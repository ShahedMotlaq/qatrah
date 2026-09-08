import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';

class OtpTimerService {
  OtpTimerService({SecureStorage? storage})
    : _storage = storage ?? getIt<SecureStorage>();

  final SecureStorage _storage;

  static const List<int> _backoff = <int>[
    5,
    30,
    60,
    15 * 60,
    60 * 60,
  ];

  Future<void> startBlock(int seconds, {int? retryLevel}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    await _storage.setOtpBlockEndTime(end);
    if (retryLevel != null) {
      await _storage.setOtpRetryLevel(retryLevel);
    }
  }

  Future<int> getRemainingSeconds() async {
    final end = await _storage.getOtpBlockEndTime();
    if (end == null) return 0;
    final diff = end.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  Future<bool> isBlocked() async {
    final end = await _storage.getOtpBlockEndTime();
    if (end == null) return false;
    return DateTime.now().isBefore(end);
  }

  Future<void> clearBlock() => _storage.clearOtpBlock();

  int getNextRetryLevel(int currentLevel) {
    final next = currentLevel + 1;
    return next > _backoff.length ? _backoff.length : next;
  }

  int secondsForLevel(int level) {
    if (level <= 0) return _backoff.first;
    final idx = level - 1;
    if (idx >= _backoff.length) return _backoff.last;
    return _backoff[idx];
  }
}
