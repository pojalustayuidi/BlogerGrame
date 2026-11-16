import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/authenticated_api_client.dart';
import '../network/backend_config.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/guest_session_manager.dart';
import '../../features/auth/data/secure_session_store.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/catalog/data/catalog_repository_impl.dart';
import '../../features/catalog/domain/catalog_repository.dart';
import '../../features/economy/data/economy_repository_impl.dart';
import '../../features/economy/domain/economy_repository.dart';
import '../../features/game/data/game_repository_impl.dart';
import '../../features/game/domain/game_repository.dart';
import '../../features/game/domain/usecases/start_or_resume_attempt.dart';
import '../../features/game/domain/usecases/submit_letter.dart';

/// Composition root. No `BackendApi()` or `Dio()` inside widgets.
final backendDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: BackendConfig.baseUrl,
    connectTimeout: const Duration(seconds: 8),
    sendTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final sessionStoreProvider = Provider<SecureSessionStore>(
    (ref) => SecureSessionStore());
final guestSessionManagerProvider = Provider<GuestSessionManager>((ref) =>
    GuestSessionManager(ref.watch(backendDioProvider),
        ref.watch(sessionStoreProvider)));
final authenticatedApiClientProvider = Provider<AuthenticatedApiClient>((ref) =>
    AuthenticatedApiClient(ref.watch(backendDioProvider),
        ref.watch(guestSessionManagerProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(ref.watch(authenticatedApiClientProvider)));
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) =>
    CatalogRepositoryImpl(ref.watch(authenticatedApiClientProvider)));
final gameRepositoryProvider = Provider<GameRepository>((ref) =>
    GameRepositoryImpl(ref.watch(authenticatedApiClientProvider)));
final economyRepositoryProvider = Provider<EconomyRepository>((ref) =>
    EconomyRepositoryImpl(ref.watch(authenticatedApiClientProvider)));

final startOrResumeAttemptProvider = Provider<StartOrResumeAttempt>((ref) =>
    StartOrResumeAttempt(ref.watch(gameRepositoryProvider)));
final submitLetterProvider = Provider<SubmitLetter>((ref) =>
    SubmitLetter(ref.watch(gameRepositoryProvider)));
