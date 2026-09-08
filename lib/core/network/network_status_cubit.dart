import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/services/connectivity_service.dart';

enum NetworkStatus { checking, online, offline }

class NetworkStatusState {
  const NetworkStatusState(
    this.status, {
    this.isInitial = false,
    this.isRechecking = false,
  });

  final NetworkStatus status;
  final bool isInitial;
  final bool isRechecking;

  bool get isChecking => status == NetworkStatus.checking;
  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;

  NetworkStatusState copyWith({
    NetworkStatus? status,
    bool? isInitial,
    bool? isRechecking,
  }) {
    return NetworkStatusState(
      status ?? this.status,
      isInitial: isInitial ?? this.isInitial,
      isRechecking: isRechecking ?? this.isRechecking,
    );
  }
}

class NetworkStatusCubit extends Cubit<NetworkStatusState> {
  NetworkStatusCubit(this._connectivityService)
    : super(const NetworkStatusState(NetworkStatus.checking, isInitial: true)) {
    _initialize();
  }

  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;

  Future<void> _initialize() async {
    await _connectivityService.initialize();
    final isConnected = await _connectivityService.hasInternetConnection();
    emit(
      NetworkStatusState(
        isConnected ? NetworkStatus.online : NetworkStatus.offline,
        isInitial: true,
      ),
    );

    _subscription = _connectivityService.statusStream.listen((isConnected) {
      emit(
        NetworkStatusState(
          isConnected ? NetworkStatus.online : NetworkStatus.offline,
        ),
      );
    });
  }

  Future<void> recheckConnection() async {
    emit(state.copyWith(isInitial: false, isRechecking: true));
    final isConnected = await _connectivityService.hasInternetConnection();
    emit(
      NetworkStatusState(
        isConnected ? NetworkStatus.online : NetworkStatus.offline,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
