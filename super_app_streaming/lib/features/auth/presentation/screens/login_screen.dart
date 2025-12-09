import 'package:flutter/material.dart';
import 'package:super_app_streaming/core/app_theme.dart'; // Asegúrate que la ruta sea correcta
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/features/auth/data/repositories/auth_repository_impl.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar el texto (los usaremos más adelante)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variable para mostrar/ocultar contraseña
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Scaffold: El lienzo básico de la pantalla
    return Scaffold(
      // SafeArea: Evita que el contenido se solape con el notch o la barra de estado
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // SingleChildScrollView: Permite hacer scroll si el teclado tapa la pantalla
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Estira los elementos a lo ancho
              children: [
                const SizedBox(height: 40),

                // 1. Logo o Título (Header)
                const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa para continuar escuchando',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // 2. Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // Oculta el texto
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                // 4. Botón "Olvidé mi contraseña"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Acción pendiente: Navegar a recuperar contraseña
                    },
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Botón de Login (Primary)
                ElevatedButton(
                  onPressed: () async {
                    // 1. Validar campos básicos
                    if (_emailController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor llena todos los campos'),
                        ),
                      );
                      return;
                    }

                    // 2. Mostrar indicador de carga (simple)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conectando con el servidor...'),
                      ),
                    );

                    try {
                      // 3. Llamada al Backend
                      final authRepo = AuthRepositoryImpl();
                      final response = await authRepo.login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );

                      // 4. Si llegamos aquí, ¡Éxito!
                      // Imprimimos el token en consola para verificar
                      print(
                        "LOGIN EXITOSO! Token: ${response['access_token']}",
                      );

                      if (context.mounted) {
                        // Navegar al Home
                        context.go('/onboarding'); // En lugar de /home
                      }
                    } catch (e) {
                      // 5. Manejar error (contraseña mal, servidor apagado, etc)
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('INICIAR SESIÓN'),
                ),

                const SizedBox(height: 40),

                // 6. Separador "O continúa con"
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'O continúa con',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // 7. Botones de Social Login (Simulados visualmente)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onTap: () {},
                    ),
                    _SocialButton(
                      icon: Icons.apple,
                      label: 'Apple',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 8. Botón ir a Registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes cuenta?"),
                    TextButton(
                      onPressed: () {
                        // Usamos context.push para APILAR una pantalla.
                        // (Aquí sí queremos que el usuario pueda volver atrás con la flecha)
                        context.push('/register');
                      },
                      child: const Text("Regístrate"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar pequeño para los botones sociales (para no repetir código)
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
