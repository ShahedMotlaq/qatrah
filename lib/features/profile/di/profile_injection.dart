import 'package:get_it/get_it.dart';
import 'package:qatrah/core/services/connectivity_service.dart';
import 'package:qatrah/features/profile/data/repositories/address_repository_impl.dart';
import 'package:qatrah/features/profile/data/repositories/hierarchy_repository_impl.dart';
import 'package:qatrah/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:qatrah/features/profile/domain/repositories/i_address_repository.dart';
import 'package:qatrah/features/profile/domain/repositories/i_hierarchy_repository.dart';
import 'package:qatrah/features/profile/domain/repositories/i_profile_repository.dart';
import 'package:qatrah/features/profile/domain/usecases/get_hierarchy_usecases.dart';
import 'package:qatrah/features/profile/domain/usecases/update_profile_usecases.dart';
import 'package:qatrah/features/profile/presentation/bloc/addresses_cubit.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';

void registerProfileDependencies(GetIt getIt) {
  getIt.registerLazySingleton<IProfileRepository>(
    () => ProfileRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<IAddressRepository>(
    () => AddressRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<IHierarchyRepository>(
    () => HierarchyRepositoryImpl(getIt()),
  );

  getIt.registerFactory(() => GetRegionsUseCase(getIt()));
  getIt.registerFactory(() => GetUnitsUseCase(getIt()));
  getIt.registerFactory(() => GetNeighborhoodsUseCase(getIt()));
  getIt.registerFactory(() => GetZonesUseCase(getIt()));
  getIt.registerFactory(() => UpdateProfileUseCase(getIt()));

  getIt.registerFactory(
    () => EditProfileBloc(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerFactory(
    () =>
        AddressesCubit(getIt(), getIt(), getIt(), getIt<ConnectivityService>()),
  );
}
