// lib/core/utils/result.dart

import 'package:qatrah/core/errors/failures.dart';

/// Generic result type for clean error handling
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  T? get data => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get error =>
      this is FailureResult<T> ? (this as FailureResult<T>).failure : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return success(self.data);
    } else if (self is FailureResult<T>) {
      return failure(self.failure);
    }
    throw StateError('Unknown Result type');
  }

  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  Result<T> onFailure(void Function(Failure failure) action) {
    if (this is FailureResult<T>) {
      action((this as FailureResult<T>).failure);
    }
    return this;
  }

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    final self = this;
    if (self is Success<T>) {
      return onSuccess(self.data);
    } else if (self is FailureResult<T>) {
      return onFailure(self.failure);
    }
    throw StateError('Unknown Result type');
  }
}

/// Success state with data
class Success<T> extends Result<T> {
  const Success(this.data);
  @override
  final T data;

  @override
  String toString() => 'Success(data: $data)';
}

/// Failure state with error - Used a different name FailureResult to avoid confusion
class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;

  @override
  String toString() => 'FailureResult(error: ${failure.errMessage})';
}
