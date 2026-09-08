import 'package:get_it/get_it.dart';
import 'package:qatrah/core/services/connectivity_service.dart';
import 'package:qatrah/features/complaints/domain/repositories/i_complaints_repository.dart';
import 'package:qatrah/features/water_feedback/data/repositories/water_feedback_repository_impl.dart';
import 'package:qatrah/features/water_feedback/domain/repositories/i_water_feedback_repository.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_bloc.dart';

void registerWaterFeedbackDependencies(GetIt getIt) {
  getIt.registerLazySingleton<IWaterFeedbackRepository>(
    () => WaterFeedbackRepositoryImpl(getIt()),
  );
  getIt.registerFactory(
    () => WaterFeedbackCubit(
      getIt(),
      getIt<IComplaintsRepository>(),
      getIt<ConnectivityService>(),
    ),
  );
}
