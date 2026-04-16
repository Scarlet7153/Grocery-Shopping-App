import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart' as network;
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/repository/auth_repository_impl.dart';
import '../../features/auth/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiClient: sl(), prefs: sl()),
  );

  //! Core
  // API Client with SharedPreferences
  sl.registerLazySingleton<network.ApiClient>(() => network.ApiClient());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
