import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:super_app_streaming/core/app_theme.dart';
import 'package:super_app_streaming/features/auth/data/repositories/auth_repository_impl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Para validar el formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Variables para la fortaleza de la contraseña
  double _passwordStrength = 0.0;
  Color _strengthColor = Colors.red;
  String _strengthText = "Débil";

  // Lógica simple para calcular fortaleza
  void _updatePasswordStrength(String password) {
    double strength = 0.0;
    if (password.length > 6) strength += 0.3;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.3; // Tiene Mayúscula
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.4; // Tiene Número

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.3) {
        _strengthColor = Colors.red;
        _strengthText = "Débil";
      } else if (strength <= 0.6) {
        _strengthColor = Colors.orange;
        _strengthText = "Media";
      } else {
        _strengthColor = Colors.green;
        _strengthText = "Fuerte";
      }
    });
  }

  // Validación de Email con Regex (Requerimiento 1.1)
  String? _validateEmail(String? value) {
    const pattern =
        r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    if (value == null || value.isEmpty) return 'El email es requerido';
    if (!regex.hasMatch(value)) return 'Ingresa un email válido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Volver al Login
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crear Cuenta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Únete gratis para escuchar música HiFi.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 32),

                  // Nombre de Usuario
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail, // Conectamos el validador
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contraseña con Listener
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (val) =>
                        _updatePasswordStrength(val), // Escuchamos cambios
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Indicador Visual de Fortaleza (Barra)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey.shade800,
                      color: _strengthColor,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _strengthText,
                      style: TextStyle(color: _strengthColor, fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 32),

// ... dentro del build ...
ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      // 1. Mostrar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creando cuenta...')),
      );

      try {
        // 2. Llamar al Backend
        final authRepo = AuthRepositoryImpl();
        
        // Usamos los controladores para enviar los datos reales
        await authRepo.register(
          "Usuario Nuevo", // O agrega un controller para username si quieres
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('¡Cuenta creada! Inicia sesión.')),
          );
          // 3. Volver al Login para que ingrese sus credenciales
          context.pop(); 
        }

      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  },
  child: const Text('REGISTRARSE'),
),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
