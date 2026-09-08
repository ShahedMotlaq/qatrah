import 'package:dio/dio.dart';
import 'package:qatrah/core/errors/failures.dart';

class ErrorFailureInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is Failure) {
      return handler.next(err);
    }
    final failure = ServerFailure.fromDioError(err);
    handler.next(
      err.copyWith(error: failure),
    );
  }
}
