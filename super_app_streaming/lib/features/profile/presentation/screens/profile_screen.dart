import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/features/auth/data/repositories/auth_repository_impl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Estado para la calidad de audio (Req 2.2)
  String _selectedQuality = 'Normal'; // Opciones: Data Saver, Normal, High, HiFi

  @override
  Widget build(BuildContext context) {
    // Datos simulados del usuario (En realidad vendrían de un UserProvider/Bloc)
    const String username = "AdminUser";
    const String email = "admin@superapp.com";
    const String avatarUrl = "https://i.pravatar.cc/300?img=11"; // Avatar de prueba

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. Cabecera del Perfil
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent, width: 3),
                    image: const DecorationImage(
                      image: CachedNetworkImageProvider(avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  username,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {}, // Pendiente: Editar Perfil
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("Editar Perfil"),
                )
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Divider(color: Colors.grey),
          const SizedBox(height: 20),

          // 2. Configuración de Calidad (Req 2.2)
          const Text("CALIDAD DE AUDIO", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 10),
          
          _buildQualityOption("Data Saver", "AAC 64kbps", Icons.data_usage),
          _buildQualityOption("Normal", "AAC 160kbps (Estándar)", Icons.music_note),
          _buildQualityOption("High", "AAC 320kbps (Alta)", Icons.hd),
          _buildQualityOption("HiFi / Master", "FLAC Lossless (Original)", Icons.graphic_eq, isPremium: true),

          const SizedBox(height: 30),

          // 3. Cerrar Sesión (Req 2.1)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String title, String subtitle, IconData icon, {bool isPremium = false}) {
    final isSelected = _selectedQuality == title;
    
    return RadioListTile<String>(
      value: title,
      groupValue: _selectedQuality,
      onChanged: (value) {
        setState(() {
          _selectedQuality = value!;
        });
        // Aquí guardaríamos la preferencia en Hive/SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Calidad cambiada a: $title"), duration: const Duration(seconds: 1)),
        );
      },
      title: Row(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.greenAccent : Colors.white)),
          if (isPremium) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
              child: const Text("PRO", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      secondary: Icon(icon, color: isSelected ? Colors.greenAccent : Colors.grey),
      activeColor: Colors.greenAccent,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("¿Cerrar sesión?"),
        content: const Text("Tendrás que ingresar tus datos nuevamente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Salir", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final repo = AuthRepositoryImpl();
      await repo.logout();
      if (mounted) {
        context.go('/login'); // Volver al inicio y borrar historial
      }
    }
  }
}