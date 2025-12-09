import 'package:dio/dio.dart';
import 'package:super_app_streaming/core/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Asegúrate de tener esta dependencia o usar SharedPreferences
import 'package:super_app_streaming/core/network/dio_client.dart';

class AuthRepositoryImpl {
  final Dio _dio = DioClient().dio;

  // Login Real
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Si llega aquí es status 200 OK.
      // Devolvemos el JSON completo (tokens + datos)
      return response.data;
      
    } on DioException catch (e) {
      // Manejo de errores HTTP (401, 500, sin internet)
      final errorMessage = e.response?.data['error'] ?? 'Error desconocido de conexión';
      throw Exception(errorMessage);
    }
  }

  // Registro Real
  Future<void> register(String username, String email, String password) async {
    try {
      await _dio.post(
        ApiConfig.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? 'No se pudo registrar';
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    // Aquí borraríamos el JWT del almacenamiento seguro.
    // Ejemplo: await const FlutterSecureStorage().deleteAll();
    
    // Por ahora simulamos un pequeño delay
    await Future.delayed(const Duration(milliseconds: 500));
  }
}