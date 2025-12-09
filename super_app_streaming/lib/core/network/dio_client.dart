import 'package:dio/dio.dart';
import 'package:super_app_streaming/core/config/api_config.dart';
import 'package:super_app_streaming/core/utils/logger_service.dart'; // Importar logger

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // INTERCEPTOR DE LOGS DETALLADOS
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.i("🌐 REQUEST [${options.method}] => ${options.uri}");
        if (options.data != null) logger.t("📦 Body: ${options.data}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        logger.d("✅ RESPONSE [${response.statusCode}] <= ${response.requestOptions.path}");
        // No logueamos data muy grande para no ensuciar, solo éxito
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        logger.e(
          "❌ ERROR [${e.response?.statusCode}] <= ${e.requestOptions.path}",
          error: e.message,
          stackTrace: e.stackTrace, // Veremos dónde falló
        );
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}