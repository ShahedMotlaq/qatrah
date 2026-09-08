import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class LoggingInterceptor {
  static PrettyDioLogger get i => PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
  );
}
