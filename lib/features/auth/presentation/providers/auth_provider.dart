// ═══════════════════════════════════════════════════════════
// AUTH PROVIDER — Presentación / Providers
// Conecta el dominio de autenticación con la UI.
// Es el único archivo de presentación que conoce AuthRepository.
// ═══════════════════════════════════════════════════════════

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Entidad del dominio — lo que la UI maneja, nunca User de Supabase
import '../../domain/entities/app_user.dart';

// Contrato abstracto — este provider solo conoce la interfaz, nunca Supabase
import '../../domain/repositories/auth_repository.dart';

// Implementación concreta — solo se referencia aquí para construir el repo
import '../../infrastructure/supabase_auth_repository.dart';

// Cliente Supabase del core — inyectado por provider, nunca instanciado aquí
import '../../../../core/supabase/supabase_client_provider.dart';

// Conecta este archivo con el código generado por build_runner
// El generador crea auth_provider.g.dart con los providers reales
part 'auth_provider.g.dart';

// ───────────────────────────────────────────────────────────
// PROVIDER DEL REPOSITORIO
// Construye y expone el repositorio de auth globalmente.
// Cualquier clase que necesite AuthRepository lo pide aquí.
// ───────────────────────────────────────────────────────────

// @riverpod sobre una función genera un Provider simple.
// El generador crea authRepositoryProvider en el .g.dart automáticamente.
// Si cambias SupabaseAuthRepository por FirebaseAuthRepository,
// solo cambias esta función — nada más en la app se toca.
@riverpod
AuthRepository authRepository(Ref ref) {
  // ← PROVIDER → PROVIDER: obtiene el cliente Supabase del core
  // El repositorio recibe el cliente por inyección, nunca lo crea solo
  final client = ref.read(supabaseClientProvider);
  return SupabaseAuthRepository(client);
}

// ───────────────────────────────────────────────────────────
// ESTADO DE AUTENTICACIÓN
// Representa los tres momentos posibles del ciclo de auth.
// La UI observa este estado para decidir qué mostrar.
// ───────────────────────────────────────────────────────────

// initial       → app recién abierta, aún verificando sesión
// authenticated → hay un usuario con sesión activa
// unauthenticated → no hay sesión, mostrar login
enum AuthStatus { initial, authenticated, unauthenticated }

// Clase inmutable que agrupa todo el estado de autenticación.
// Inmutable porque Riverpod detecta cambios por referencia —
// si mutas el objeto sin crear uno nuevo, la UI no se actualiza.
class AuthState {
  final AuthStatus status;
  final AppUser? user;          // null cuando no hay sesión activa
  final String? errorMessage;   // null cuando no hay error

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  // copyWith crea una copia con campos modificados sin mutar el original.
  // Patrón estándar para estados inmutables en Riverpod.
  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      // errorMessage no usa ?? para permitir limpiarlo con null explícito
      errorMessage: errorMessage,
    );
  }
}

// ───────────────────────────────────────────────────────────
// NOTIFIER DE AUTENTICACIÓN
// Maneja toda la lógica de auth fuera de la UI.
// ← PROVIDER → SCREEN: la UI consume authNotifierProvider
// ───────────────────────────────────────────────────────────

// @riverpod sobre una clase genera un NotifierProvider automáticamente.
// El generador crea authNotifierProvider en el .g.dart.
// La clase extiende _$AuthNotifier — también generado por build_runner.
@riverpod
class AuthNotifier extends _$AuthNotifier {

  // build() es el initState() de Riverpod con @riverpod.
  // Se ejecuta una vez al crear el provider y define el estado inicial.
  // Retorna AuthState, que es el tipo del estado de este Notifier.
  @override
  AuthState build() {
    // ← PROVIDER → PROVIDER: consulta sesión activa al arrancar la app
    // Supabase persiste la sesión en disco — si el usuario ya estaba
    // logueado, getCurrentUser() retorna su AppUser directamente
    final user = ref.read(authRepositoryProvider).getCurrentUser();

    if (user != null) {
      // Hay sesión activa — la UI debe mostrar el home directamente
      return AuthState(status: AuthStatus.authenticated, user: user);
    }

    // No hay sesión — la UI debe mostrar el login
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  // Registra un usuario nuevo en Supabase Auth.
  // Cuando termina, actualiza state → la UI se reconstruye automáticamente.
  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      // ← PROVIDER → PROVIDER: delega el registro al repositorio de auth
      final user = await ref.read(authRepositoryProvider).register(
        email: email,
        password: password,
      );
      // Registro exitoso — actualizamos state con el usuario creado
      // ← PROVIDER → SCREEN: este cambio de state reconstruye LoginScreen
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      // Error de Supabase Auth — credenciales, email duplicado, etc.
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      // Error inesperado — red, timeout, etc.
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  // Inicia sesión con email y password.
  // Mismo patrón que register — delega, actualiza state, UI reacciona.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // ← PROVIDER → PROVIDER: delega el login al repositorio de auth
      final user = await ref.read(authRepositoryProvider).login(
        email: email,
        password: password,
      );
      // Login exitoso — GoRouter detecta el cambio y redirige al home
      // ← PROVIDER → SCREEN: este cambio de state reconstruye LoginScreen
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  // Cierra la sesión del usuario actual.
  // GoRouter detecta el cambio de state y redirige al login automáticamente.
  Future<void> logout() async {
    // ← PROVIDER → PROVIDER: delega el logout al repositorio de auth
    await ref.read(authRepositoryProvider).logout();
    // ← PROVIDER → SCREEN: este cambio de state reconstruye HomeScreen
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}