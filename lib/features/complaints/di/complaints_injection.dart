import 'package:get_it/get_it.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/complaints/data/repositories/complaints_repository_impl.dart';
import 'package:qatrah/features/complaints/domain/repositories/i_complaints_repository.dart';
import 'package:qatrah/features/complaints/domain/usecases/complaint_usecases.dart';
import 'package:qatrah/features/complaints/presentation/bloc/complaints_bloc.dart';

void registerComplaintsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<IComplaintsRepository>(
    () => ComplaintsRepositoryImpl(
      getIt<ApiService>(),
      getIt<SecureStorage>(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetMyComplaintsUseCase(getIt<IComplaintsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetScopedComplaintsForEmployeeUseCase(getIt<IComplaintsRepository>()),
  );
  getIt.registerLazySingleton(
    () => CreateComplaintUseCase(getIt<IComplaintsRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetComplaintsByNeighborhoodUseCase(getIt<IComplaintsRepository>()),
  );
  getIt.registerLazySingleton(
    () => RespondToComplaintUseCase(getIt<IComplaintsRepository>()),
  );
  getIt.registerFactory(
    () => ComplaintsBloc(
      getIt<GetMyComplaintsUseCase>(),
      getIt<GetScopedComplaintsForEmployeeUseCase>(),
      getIt<CreateComplaintUseCase>(),
      getIt<RespondToComplaintUseCase>(),
    ),
  );
}
