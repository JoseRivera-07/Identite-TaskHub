import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

// Implementación concreta del contrato AuthRepository usando Supabase.
// Es la ÚNICA clase en todo el proyecto que importa Supabase para auth.
// Presentation y Domain nunca saben que Supabase existe.
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  // Recibe el cliente por inyección de dependencias desde el provider.
  // Nunca llama a Supabase.instance.client directamente —
  // eso lo hace el provider que construye esta clase.
  const SupabaseAuthRepository(this._client);

  // Registra un usuario nuevo en Supabase Auth.
  // Mapea el User de Supabase a AppUser antes de retornar.
  @override
  Future<AppUser> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    // Si Supabase no retorna un usuario, algo falló
    if (response.user == null) {
      throw Exception('Error al registrar usuario');
    }

    // Mapeamos User de Supabase → AppUser del dominio
    return _mapToAppUser(response.user!);
  }

  // Inicia sesión con email y password en Supabase Auth.
  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Credenciales incorrectas');
    }

    return _mapToAppUser(response.user!);
  }

  // Cierra la sesión en Supabase — invalida el JWT del usuario
  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Retorna el usuario de la sesión activa o null si no hay sesión.
  // Supabase guarda la sesión en disco — sobrevive al cerrar la app.
  @override
  AppUser? getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapToAppUser(user);
  }

  // Stream que Supabase emite cada vez que cambia el estado de auth.
  // Login → emite AppUser | Logout → emite null
  // GoRouter lo escucha para redirigir automáticamente.
  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      // event.session?.user es null cuando el usuario cierra sesión
      if (event.session?.user == null) return null;
      return _mapToAppUser(event.session!.user);
    });
  }

  // Método privado de mapeo — convierte User de Supabase en AppUser.
  // Privado porque es un detalle de implementación de esta clase.
  // El dominio no necesita saber cómo se hace la conversión.
  AppUser _mapToAppUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
    );
  }
}