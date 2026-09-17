import 'package:get_it/get_it.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/sse_client.dart';
import 'package:qatrah/features/home/data/realtime/pumping_stream_service.dart';
import 'package:qatrah/features/home/data/repositories/home_repository_impl.dart';
import 'package:qatrah/features/home/domain/repositories/i_home_repository.dart';
import 'package:qatrah/features/home/domain/usecases/get_all_areas_use_case.dart';
import 'package:qatrah/features/home/domain/usecases/get_pumping_status_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/get_upcoming_schedules_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/get_watched_areas_usecase.dart';
import 'package:qatrah/features/home/domain/usecases/toggle_area_selection_usecase.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';

void registerHomeDependencies(GetIt getIt) {
  getIt.registerLazySingleton<IHomeRepository>(
    () => HomeRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => GetWatchedAreasUseCase(getIt<IHomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetPumpingStatusUseCase(getIt<IHomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetUpcomingSchedulesUseCase(getIt<IHomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => ToggleAreaWatchUseCase(getIt<IHomeRepository>()),
  );
  getIt.registerLazySingleton(
    () => GetAllAreasUseCase(getIt<IHomeRepository>()),
  );

  // A factory, not a singleton: each HomeBloc owns its stream and closes it.
  getIt.registerFactory(
    () => PumpingStreamService(SseClient(getIt<ApiClient>().dio)),
  );

  getIt.registerFactory(
    () => HomeBloc(
      getWatchedAreas: getIt(),
      getPumpingStatus: getIt(),
      getUpcomingSchedules: getIt(),
      toggleAreaWatch: getIt(),
      hierarchyRepository: getIt(),
      profileRepository: getIt(),
      secureStorage: getIt(),
      pumpingStream: getIt(),
    ),
  );
}
