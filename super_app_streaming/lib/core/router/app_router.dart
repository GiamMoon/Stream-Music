import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/login_screen.dart';
import 'package:super_app_streaming/features/home/presentation/screens/home_screen.dart';
import 'package:super_app_streaming/features/auth/presentation/screens/register_screen.dart';
import 'package:super_app_streaming/features/onboarding/presentation/screens/taste_selection_screen.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';
import 'package:super_app_streaming/features/player/presentation/screens/player_screen.dart';
import 'package:super_app_streaming/features/profile/presentation/screens/profile_screen.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';
import 'package:super_app_streaming/features/player/presentation/screens/lyrics_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login', 
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: '/home',
      builder: (context, state) {
        final playlist = state.extra as Playlist?; 
        return HomeScreen(initialPlaylist: playlist);
      },
    ),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const TasteSelectionScreen(),
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) {
        final map = state.extra as Map<String, dynamic>;
        final playlist = map['playlist'] as List<Track>;
        final index = map['index'] as int;
        
        return CustomTransitionPage(
          key: state.pageKey,
          child: PlayerScreen(playlist: playlist, initialIndex: index),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tween), child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    // RUTA NUEVA PARA LETRAS
    GoRoute(
      path: '/lyrics',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final artworkUrl = extra['artworkUrl'] as String;
        final lyrics = extra['lyrics'] as List<Lyric>;

        return CustomTransitionPage(
          key: state.pageKey,
          child: LyricsScreen(artworkUrl: artworkUrl, lyrics: lyrics),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Transición vertical suave
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