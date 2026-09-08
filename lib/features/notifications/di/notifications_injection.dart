import 'package:get_it/get_it.dart';
import 'package:qatrah/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:qatrah/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:qatrah/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_cubit.dart';

void registerNotificationsDependencies(GetIt getIt) {
  getIt.registerLazySingleton<INotificationsRepository>(
    () => NotificationsRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => GetNotificationsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetPublicNotificationsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetUnreadCountUseCase(getIt()));
  getIt.registerLazySingleton(() => MarkNotificationAsReadUseCase(getIt()));
  getIt.registerFactory(
    () => NotificationsCubit(getIt(), getIt(), getIt(), getIt()),
  );
}
