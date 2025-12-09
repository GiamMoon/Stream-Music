import 'package:logger/logger.dart';

// Instancia global para usar en toda la app
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // 0 para mensajes cortos, 2 para errores con traza
    errorMethodCount: 8, // Si hay error, muestra 8 líneas del stack trace
    lineLength: 120, // Ancho de la línea
    colors: true, // Colores en la consola (Android Studio/VS Code)
    printEmojis: true, // 🐛 🔥 💡
    printTime: true, // Muestra la hora exacta del evento
  ),
);

// Guía de uso:
// logger.t("Trace"); // Gris (Detalles finos)
// logger.d("Debug"); // Azul (Flujo normal)
// logger.i("Info");  // Verde (Eventos importantes: Login, Navegación)
// logger.w("Warn");  // Naranja (Algo raro pero no fatal)
// logger.e("Error"); // Rojo (Fallos críticos con Stack Trace)