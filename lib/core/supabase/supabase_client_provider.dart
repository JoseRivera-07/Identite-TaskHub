import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider que expone el cliente de Supabase globalmente.
// Al ser un Provider simple (no StateProvider ni NotifierProvider)
// significa que este valor nunca cambia — siempre es el mismo cliente.
//
// Cualquier repositorio que necesite hablar con Supabase
// accede al cliente a través de este provider, nunca directamente.
// Esto permite reemplazarlo por un mock en tests sin tocar
// una sola línea de los repositorios.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  // Supabase.instance.client es el singleton inicializado en main.dart
  // Si intentas acceder a esto antes de Supabase.initialize(), lanza error
  return Supabase.instance.client;
});