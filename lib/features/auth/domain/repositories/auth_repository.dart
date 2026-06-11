// DOMINIO PURO — solo importa entidades del propio dominio
// Cero Supabase, cero Flutter, cero librerías externas
import '../entities/app_user.dart';

// Contrato abstracto de autenticación.
// Define QUÉ operaciones existen — no CÓMO se implementan.
//
// El dominio solo conoce esta interfaz.
// La capa de infrastructure la implementa con Supabase.
// Si mañana cambias a Firebase, creas SupabaseAuthRepository
// y lo reemplazas — el dominio no se entera del cambio.
abstract class AuthRepository {

  // Registra un usuario nuevo con email y password.
  // Retorna el AppUser creado o lanza una excepción si falla.
  Future<AppUser> register({
    required String email,
    required String password,
  });

  // Inicia sesión con email y password.
  // Retorna el AppUser autenticado o lanza una excepción si falla.
  Future<AppUser> login({
    required String email,
    required String password,
  });

  // Cierra la sesión del usuario actual.
  Future<void> logout();

  // Retorna el usuario actualmente autenticado.
  // Retorna null si no hay sesión activa.
  // Útil para verificar si el usuario ya estaba logueado al abrir la app.
  AppUser? getCurrentUser();

  // Stream que emite cada vez que el estado de autenticación cambia.
  // Emite AppUser cuando hay sesión activa, null cuando no la hay.
  // GoRouter lo escucha para redirigir automáticamente entre login y home.
  Stream<AppUser?> get authStateChanges;
}