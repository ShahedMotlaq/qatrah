import 'dart:async';

enum NetworkAlertType { noInternet, serverError }

class NetworkAlertService {
  NetworkAlertService._();
  static final NetworkAlertService instance = NetworkAlertService._();

  final _controller = StreamController<NetworkAlertType>.broadcast();

  Stream<NetworkAlertType> get alerts => _controller.stream;

  DateTime? _lastNoInternetAlert;
  DateTime? _lastServerErrorAlert;

  static const _throttleDuration = Duration(seconds: 5);

  void notifyNoInternet() {
    final now = DateTime.now();
    if (_lastNoInternetAlert != null &&
        now.difference(_lastNoInternetAlert!) < _throttleDuration) {
      return;
    }
    _lastNoInternetAlert = now;
    _controller.add(NetworkAlertType.noInternet);
  }

  void notifyServerError() {
    final now = DateTime.now();
    if (_lastServerErrorAlert != null &&
        now.difference(_lastServerErrorAlert!) < _throttleDuration) {
      return;
    }
    _lastServerErrorAlert = now;
    _controller.add(NetworkAlertType.serverError);
  }

  void dispose() {
    _controller.close();
  }
}
