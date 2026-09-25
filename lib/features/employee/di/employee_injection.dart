import 'package:get_it/get_it.dart';
import 'package:qatrah/features/employee/data/realtime/operator_pumping_sse_service.dart';
import 'package:qatrah/features/employee/data/repositories/dashboard_repository_impl.dart';
import 'package:qatrah/features/employee/domain/repositories/i_employee_repository.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/statistics_cubit.dart';

void registerEmployeeDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<IDashboardRepository>(
      () => DashboardRepositoryImpl(getIt()),
    )
    // Factory: the bloc closes it, and a closed client never reopens.
    ..registerFactory(() => OperatorPumpingSseService(getIt()))
    ..registerFactory(
      () => DashboardBloc(getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => StatisticsCubit(getIt()));
}
