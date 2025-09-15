import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:metrix/config/constants.dart';
import 'package:metrix/data/models/user.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: 'access_token');

            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            handler.next(options);
          } catch (e) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Failed to read access token: $e',
              ),
            );
          }
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = await _storage.read(key: 'refresh_token');
              if (refreshToken != null) {
                final response = await _refreshToken(refreshToken);
                if (response != null) {
                  await _saveTokens(
                    response.data['access_token'],
                    response.data['refresh_token'],
                  );
                  final cloneReq = await _retryRequest(
                    error.requestOptions,
                    response.data['access_token'],
                  );
                  handler.resolve(cloneReq);
                  return;
                } else {}
              }
              await _clearTokens();
              handler.next(error);
            } catch (e) {
              await _clearTokens();
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<Response?> _refreshToken(String refreshToken) async {
    try {
      final tempDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
      final response = await tempDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
    ]);
  }

  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

    return await _dio.request(
      requestOptions.path,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  Future<User?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        await _saveTokens(
          response.data['access_token'],
          response.data['refresh_token'],
        );
        return User.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (e) {
      throw (e.toString());
    } finally {
      await _clearTokens();
    }
  }
}
