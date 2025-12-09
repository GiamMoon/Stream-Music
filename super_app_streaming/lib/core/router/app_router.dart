import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/core/router/main_wrapper.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/login_screen.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/register_screen.dart';
import 'package:super_app_streaming/features/home/presentation/screens/home_screen.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/music/domain/models/album.dart';
import 'package:super_app_streaming/features/music/domain/models/artist.dart'; // <--- IMPORTANTE: Importar Artist
import 'package:super_app_streaming/features/music/presentation/screens/album_detail_screen.dart';
import 'package:super_app_streaming/features/music/presentation/screens/artist_detail_screen.dart'; // <--- IMPORTANTE: Importar Pantalla
import 'package:super_app_streaming/features/onboarding/presentation/screens/taste_selection_screen.dart';
import 'package:super_app_streaming/features/player/presentation/screens/lyrics_screen.dart';
import 'package:super_app_streaming/features/profile/presentation/screens/profile_screen.dart';

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

    // --- SHELL ROUTE (Con reproductor persistente) ---
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainWrapper(child: child);
      },
      routes: [
        // HOME
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final playlist = extra?['playlist'] as Playlist?;
            final artistIds = extra?['artistIds'] as List<String>?;

            return HomeScreen(
              initialPlaylist: playlist, 
              selectedArtistIds: artistIds ?? [], 
            );
          },
        ),
        
        // PERFIL USUARIO
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // DETALLE DE ÁLBUM
        GoRoute(
          path: '/album_detail',
          builder: (context, state) {
            final album = state.extra as Album; 
            return AlbumDetailScreen(album: album);
          },
        ),

        // DETALLE DE ARTISTA (Nueva ruta)
        GoRoute(
          path: '/artist_detail',
          builder: (context, state) {
            // Recibimos el objeto Artist completo al navegar
            final artist = state.extra as Artist; 
            return ArtistDetailScreen(artist: artist);
          },
        ),
      ],
    ),

    // --- LYRICS (Pantalla completa, tapa todo) ---
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/lyrics',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CustomTransitionPage(
          child: LyricsScreen(
            artworkUrl: extra['artworkUrl'], 
            lyrics: extra['lyrics']
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        );
      },
    ),
  ],
);