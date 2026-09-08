import 'package:get_it/get_it.dart';
import 'package:qatrah/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:qatrah/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';

void registerAuthDependencies(GetIt getIt) {
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );
  getIt.registerFactory(OtpBloc.new);
}
