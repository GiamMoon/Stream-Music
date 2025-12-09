import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/core/router/main_wrapper.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/login_screen.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/register_screen.dart';
import 'package:super_app_streaming/features/home/presentation/screens/home_screen.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart'; // IMPORTANTE: Importar Playlist/Track
import 'package:super_app_streaming/features/onboarding/presentation/screens/taste_selection_screen.dart';
import 'package:super_app_streaming/features/player/presentation/screens/lyrics_screen.dart';
import 'package:super_app_streaming/features/profile/presentation/screens/profile_screen.dart';

// Claves globales para navegación
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    // --- RUTAS SIN REPRODUCTOR ---
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const TasteSelectionScreen(),
    ),

    // --- RUTAS CON REPRODUCTOR PERSISTENTE (ShellRoute) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) {
            // CORRECCIÓN AQUÍ: Recibimos la playlist y se la pasamos al Home
            final playlist = state.extra as Playlist?;
            return HomeScreen(initialPlaylist: playlist);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // --- OTRAS PANTALLAS (Lyrics) ---
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/lyrics',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final artworkUrl = extra['artworkUrl'] as String;
        final lyrics = extra['lyrics'] as List<Lyric>;

        return CustomTransitionPage(
          key: state.pageKey,
          child: LyricsScreen(artworkUrl: artworkUrl, lyrics: lyrics),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        );
      },
    ),
  ],
);