// SDK de Flutter — widgets, Material Design, toda la UI base
import 'package:flutter/material.dart';

// flutter_dotenv — lee el archivo .env y expone las variables
// Así nunca escribes credenciales directamente en el código
import 'package:flutter_dotenv/flutter_dotenv.dart';

// flutter_riverpod — expone ProviderScope, el contenedor
// global que hace que todos los providers funcionen
import 'package:flutter_riverpod/flutter_riverpod.dart';

// supabase_flutter — expone Supabase.initialize() y el cliente
// que usaremos para auth y base de datos en toda la app
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';

// main() es async porque necesita esperar operaciones
// que toman tiempo antes de mostrar la UI
void main() async {
  // SIEMPRE primera línea cuando hay async en main()
  // Conecta el framework Dart con el motor nativo de Flutter
  // Sin esto, cualquier await anterior a runApp() puede fallar
  WidgetsFlutterBinding.ensureInitialized();

  // Espera a que .env esté completamente cargado en memoria
  // antes de intentar leer cualquier variable de entorno
  await dotenv.load(fileName: '.env');

  // Espera a que Supabase establezca conexión y esté listo
  // antes de que cualquier widget intente hacer queries
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // ! = "confío en que existe"
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Solo cuando TODO lo anterior está listo, arranca la UI
  // runApp() recibe el widget raíz de toda la aplicación
  runApp(
    // ProviderScope DEBE ser el widget más externo
    // Es el contenedor global donde Riverpod guarda todos los estados
    // Si un widget queda fuera de este scope, no puede usar providers
    const ProviderScope(
      // overrides: [] ← aquí se inyectan providers falsos en tests
      child: MyApp(),
    ),
  );
}

// MyApp debe ser una clase, no una función
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      // Nombre de la aplicación usado por el sistema operativo
      title: 'Identite TaskHub',

      // Oculta la cinta roja de "Debug" en la esquina superior derecha
      debugShowCheckedModeBanner: false,

      // Configuración visual global de la aplicación
      // Todos los widgets heredarán este tema por defecto
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 91, 36, 3),
        ),

        // Activa los componetes y estilos de Material Design 3 (Material You)
        useMaterial3: true,
      ),

      // Pantalla inicial que se muestra al abrir la aplicación
      // ← PROVIDER → SCREEN: MyApp consume appRouterProvider
      // El router maneja toda la navegación incluyendo los guards de auth
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
