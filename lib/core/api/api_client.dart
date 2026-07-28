import 'dart:async';
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'api_exception.dart';

/// Wraps a Dio instance pointed at the EazyDR FastAPI backend.
/// - Every request under /api/v1 gets the Bearer access token attached
///   automatically when one is stored.
/// - On a 401 (other than the auth endpoints themselves) it attempts a
///   single silent refresh via POST /api/v1/auth/refresh, retries the
///   original request once, and otherwise surfaces a session-expired
///   ApiException so the UI can route back to Auth.
class ApiClient {
  final Dio dio;
  final LocalStorage storage;
  void Function()? onSessionExpired;

  ApiClient(this.storage) : dio = Dio() {
    dio.options.baseUrl = storage.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 20);
    dio.options.receiveTimeout = const Duration(seconds: 20);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = storage.accessToken;
        if (token != null &&
            !options.path.contains('/auth/login') &&
            !options.path.contains('/auth/register') &&
            !options.path.contains('/auth/otp') &&
            !options.path.contains('/auth/forgot-password') &&
            !options.path.contains('/auth/reset-password') &&
            !options.path.contains('/auth/refresh')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthRoute = error.requestOptions.path.contains('/auth/');
        if (error.response?.statusCode == 401 &&
            !isAuthRoute &&
            storage.refreshToken != null) {
          try {
            final refreshed = await _refresh();
            if (refreshed) {
              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer ${storage.accessToken}';
              final response = await dio.fetch(req);
              return handler.resolve(response);
            }
          } on DioException catch (refreshError) {
            // Only a definitive rejection from the server (the refresh
            // token itself is invalid/expired/revoked) means the session
            // is truly over. A network error, timeout, or server
            // cold-start (e.g. Render free tier waking up) while calling
            // /auth/refresh is NOT proof the session is invalid — don't
            // wipe the tokens for that; just let this request fail and
            // let the app retry later with the still-valid refresh token.
            final refreshStatus = refreshError.response?.statusCode;
            if (refreshStatus == 401 || refreshStatus == 400) {
              await storage.clearTokens();
              onSessionExpired?.call();
            }
            return handler.next(error);
          } catch (_) {
            // Unexpected non-network error — be conservative, don't log out.
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  Future<bool> _refresh() async {
    final refreshToken = storage.refreshToken;
    if (refreshToken == null) return false;
    final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
        .post('/api/v1/auth/refresh', data: {'refresh_token': refreshToken});
    final data = response.data as Map<String, dynamic>;
    await storage.saveTokens(
        access: data['access_token'], refresh: data['refresh_token']);
    return true;
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get(path, queryParameters: query));

  Future<Response> post(String path, {dynamic data}) =>
      _wrap(() => dio.post(path, data: data));

  Future<Response> patch(String path, {dynamic data}) =>
      _wrap(() => dio.patch(path, data: data));

  Future<Response> delete(String path) => _wrap(() => dio.delete(path));

  Future<Response> postForm(String path, FormData data) =>
      _wrap(() => dio.post(path, data: data));

  Future<Response> _wrap(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response?.data['detail']?.toString())
          : null;
      throw ApiException(detail ?? e.message ?? 'Network error',
          statusCode: e.response?.statusCode);
    }
  }
}
