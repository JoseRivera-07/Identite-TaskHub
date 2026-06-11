// ═══════════════════════════════════════════════════════════
// APP ROUTER — Core / Router
// Centraliza toda la navegación de la app.
// Incluye guards que protegen rutas según estado de autenticación.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/trash_screen.dart';

part 'app_router.g.dart';

// ───────────────────────────────────────────────────────────
// REFRESH NOTIFIER
// Puente entre el estado de Riverpod y GoRouter.
// GoRouter no entiende providers — necesita un ChangeNotifier.
// ───────────────────────────────────────────────────────────

// GoRouter escucha este ChangeNotifier para re-evaluar los guards
// cada vez que el estado de autenticación cambia.
// Sin esto, GoRouter solo evaluaría los guards al arrancar la app.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier(this._ref) {
    // Escucha cambios en authNotifierProvider
    // Cada vez que el estado de auth cambia, notifica a GoRouter
    _ref.listen(authProvider, (previous, next) => notifyListeners());
  }

  final Ref _ref;
}

// ───────────────────────────────────────────────────────────
// ROUTER PROVIDER
// Expone el GoRouter configurado con guards de autenticación.
// ← PROVIDER → SCREEN: MyApp consume este provider para configurar rutas
// ───────────────────────────────────────────────────────────

// @riverpod genera appRouterProvider en el .g.dart
@riverpod
GoRouter appRouter(Ref ref) {
  // Crea el notifier que mantiene GoRouter sincronizado con Riverpod
  final authNotifier = AuthStateNotifier(ref);

  return GoRouter(
    // Ruta inicial al abrir la app
    initialLocation: '/login',

    // refreshListenable re-evalúa el redirect cada vez que
    // AuthStateNotifier llama a notifyListeners()
    refreshListenable: authNotifier,

    // redirect se ejecuta antes de cada navegación
    // Aquí decidimos si el usuario puede acceder a la ruta solicitada
    redirect: (context, state) {
      // ← PROVIDER → PROVIDER: lee el estado actual de autenticación
      final authState = ref.read(authProvider);
      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isInitial =
          authState.status == AuthStatus.initial;

      // Mientras verificamos la sesión no redirigimos a ningún lado
      if (isInitial) return null;

      // Rutas que no requieren autenticación
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si no está autenticado y trata de acceder a una ruta protegida
      // → redirige al login
      if (!isAuthenticated && !isOnAuthRoute) return '/login';

      // Si ya está autenticado y trata de ir al login o registro
      // → redirige al home
      if (isAuthenticated && isOnAuthRoute) return '/';

      // En cualquier otro caso deja pasar la navegación
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        // ← ROUTER → SCREEN: GoRouter construye LoginScreen
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        // ← ROUTER → SCREEN: GoRouter construye RegisterScreen
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        // ← ROUTER → SCREEN: GoRouter construye HomeScreen
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'trash',
            name: 'trash',
            // ← ROUTER → SCREEN: GoRouter construye TrashScreen
            builder: (context, state) => const TrashScreen(),
          ),
        ],
      ),
    ],

    // Página de error para rutas no encontradas
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.error}'),
      ),
    ),
  );
}