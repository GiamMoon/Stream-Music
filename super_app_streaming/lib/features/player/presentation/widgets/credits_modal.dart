import 'package:flutter/material.dart';
import 'package:super_app_streaming/features/music/domain/models/track.dart';

class CreditsModal extends StatelessWidget {
  final Track track;

  const CreditsModal({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Fondo oscuro puro
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Créditos de la canción",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 30),

          // Secciones de Créditos
          _CreditSection(title: "INTERPRETADA POR", content: [track.artistName]),
          const Divider(color: Colors.grey),
          _CreditSection(title: "ESCRITA POR", content: track.writers),
          const Divider(color: Colors.grey),
          _CreditSection(title: "PRODUCIDA POR", content: track.producers),
          const Divider(color: Colors.grey),
          
          const SizedBox(height: 10),
          Text(
            "Sello: ${track.label}",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 40), // Espacio para safe area
        ],
      ),
    );
  }
}

class _CreditSection extends StatelessWidget {
  final String title;
  final List<String> content;

  const _CreditSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...content.map((name) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          )),
        ],
      ),
    );
  }
}