// DOMINIO PURO — cero imports de Flutter o Supabase
// Este archivo puede copiarse a cualquier proyecto Dart y funciona igual

// AppUser es la representación oficial de un usuario autenticado
// en este sistema. Es el lenguaje común entre todas las capas.
// Presentation lo usa para mostrar datos.
// Infrastructure lo construye desde la respuesta de Supabase.
class AppUser {
  final String id;      // UUID que genera Supabase Auth
  final String email;   // Email con el que se registró

  const AppUser({
    required this.id,
    required this.email,
  });

  // copyWith permite crear una copia modificada sin mutar el original.
  // Importante en Riverpod donde el estado debe ser inmutable.
  AppUser copyWith({
    String? id,
    String? email,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
    );
  }

  // Útil para debugging — cuando imprimes un AppUser ves algo legible
  @override
  String toString() => 'AppUser(id: $id, email: $email)';

  // Dos AppUser son iguales si tienen el mismo ID
  // Necesario para comparaciones en listas y sets
  // Override para indicar que estámos personalizando métodos heredados de Object
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}