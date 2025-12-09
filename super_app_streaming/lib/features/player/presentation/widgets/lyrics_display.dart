import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:super_app_streaming/features/music/domain/models/lyric.dart';

class LyricsDisplay extends StatefulWidget {
  final List<Lyric> lyrics;
  final Duration currentPosition;
  final VoidCallback? onTap; // Para cerrar/ocultar si se desea

  const LyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    this.onTap,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Algoritmo de Sincronización:
    // Buscamos la última línea cuyo tiempo sea menor o igual a la posición actual
    // Ejemplo: Si la canción va en 0:15, y hay líneas en 0:10 y 0:20, la activa es la de 0:10.
    int newIndex = widget.lyrics.lastIndexWhere(
      (lyric) => lyric.time <= widget.currentPosition,
    );

    // Si encontramos una nueva línea activa y es diferente a la anterior
    if (newIndex != -1 && newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      
      // Auto-Scroll suave hacia la nueva línea
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: newIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.5, // 0.5 significa "centrar la línea en la pantalla"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.isEmpty) {
      return const Center(
        child: Text("Sin letras disponibles", style: TextStyle(color: Colors.white54)),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.transparent, // Fondo semitransparente oscuro
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: widget.lyrics.length,
          itemBuilder: (context, index) {
            final lyric = widget.lyrics[index];
            final isActive = index == _currentIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isActive ? 28 : 20, // La activa es más grande
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4), // Inactivas tenues
                  height: 1.5,
                ),
                child: Text(
                  lyric.text,
                  textAlign: TextAlign.start, // Estilo Apple Music: alineado a la izq o centro
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}