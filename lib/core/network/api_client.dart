import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final http.Client client;
  
  ApiClient({required this.client});
  
  Future<dynamic> get(String endpoint) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      AppLogger.network('GET Request: $url', 'ApiClient');
      
      final response = await client
          .get(
            Uri.parse(url),
            headers: ApiConstants.headers,
          )
          .timeout(ApiConstants.timeout);
      
      AppLogger.success('GET Response: ${response.statusCode}', 'ApiClient');
      return _handleResponse(response);
    } on SocketException catch (e, stackTrace) {
      AppLogger.error('No internet connection', e, stackTrace, 'ApiClient');
      throw const NetworkException('No internet connection. Please check your network settings.');
    } on http.ClientException catch (e, stackTrace) {
      AppLogger.error('Client exception', e, stackTrace, 'ApiClient');
      throw NetworkException('Connection error: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Request timeout', e, stackTrace, 'ApiClient');
      throw const NetworkException('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error', e, stackTrace, 'ApiClient');
      throw NetworkException('Unexpected error: $e');
    }
  }
  
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      AppLogger.network('POST Request: $url', 'ApiClient');
      AppLogger.data('Body: ${jsonEncode(body)}', 'ApiClient');
      
      final response = await client
          .post(
            Uri.parse(url),
            headers: ApiConstants.headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.timeout);
      
      AppLogger.success('POST Response: ${response.statusCode}', 'ApiClient');
      AppLogger.response('Response body: ${response.body}', 'ApiClient');
      
      return _handleResponse(response);
    } on SocketException catch (e, stackTrace) {
      AppLogger.error('No internet connection', e, stackTrace, 'ApiClient');
      throw const NetworkException('No internet connection. Please check your network settings.');
    } on http.ClientException catch (e, stackTrace) {
      AppLogger.error('Client exception', e, stackTrace, 'ApiClient');
      throw NetworkException('Connection error: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Request timeout', e, stackTrace, 'ApiClient');
      throw const NetworkException('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error', e, stackTrace, 'ApiClient');
      throw NetworkException('Unexpected error: $e');
    }
  }
  
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      AppLogger.network('PUT Request: $url', 'ApiClient');
      AppLogger.data('Body: ${jsonEncode(body)}', 'ApiClient');
      
      final response = await client
          .put(
            Uri.parse(url),
            headers: ApiConstants.headers,
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.timeout);
      
      AppLogger.success('PUT Response: ${response.statusCode}', 'ApiClient');
      AppLogger.response('Response body: ${response.body}', 'ApiClient');
      
      return _handleResponse(response);
    } on SocketException catch (e, stackTrace) {
      AppLogger.error('No internet connection', e, stackTrace, 'ApiClient');
      throw const NetworkException('No internet connection. Please check your network settings.');
    } on http.ClientException catch (e, stackTrace) {
      AppLogger.error('Client exception', e, stackTrace, 'ApiClient');
      throw NetworkException('Connection error: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Request timeout', e, stackTrace, 'ApiClient');
      throw const NetworkException('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error', e, stackTrace, 'ApiClient');
      throw NetworkException('Unexpected error: $e');
    }
  }
  
  Future<void> delete(String endpoint) async {
    try {
      final url = '${ApiConstants.baseUrl}$endpoint';
      AppLogger.network('DELETE Request: $url', 'ApiClient');
      
      final response = await client
          .delete(
            Uri.parse(url),
            headers: ApiConstants.headers,
          )
          .timeout(ApiConstants.timeout);
      
      AppLogger.success('DELETE Response: ${response.statusCode}', 'ApiClient');
      
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerException('Failed to delete: ${response.statusCode}');
      }
    } on SocketException catch (e, stackTrace) {
      AppLogger.error('No internet connection', e, stackTrace, 'ApiClient');
      throw const NetworkException('No internet connection. Please check your network settings.');
    } on http.ClientException catch (e, stackTrace) {
      AppLogger.error('Client exception', e, stackTrace, 'ApiClient');
      throw NetworkException('Connection error: ${e.message}');
    } on TimeoutException catch (e, stackTrace) {
      AppLogger.error('Request timeout', e, stackTrace, 'ApiClient');
      throw const NetworkException('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error', e, stackTrace, 'ApiClient');
      throw NetworkException('Unexpected error: $e');
    }
  }
  
  dynamic _handleResponse(http.Response response) {
    // Manejo especial para redirecciones
    if (response.statusCode == 307 || response.statusCode == 308) {
      AppLogger.warning(
        'Redirect detected: ${response.statusCode}',
        'ApiClient'
      );
      AppLogger.info(
        'Location header: ${response.headers['location']}',
        'ApiClient'
      );
      throw const ServerException(
        'Server redirect detected. Please check the API URL configuration.'
      );
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e, stackTrace) {
        AppLogger.error('JSON decode error', e, stackTrace, 'ApiClient');
        AppLogger.response('Raw response: ${response.body}', 'ApiClient');
        throw const ServerException('Invalid response format');
      }
    } else if (response.statusCode == 404) {
      throw const ServerException('Resource not found');
    } else if (response.statusCode == 400) {
      try {
        final error = jsonDecode(response.body);
        throw ServerException(error['detail'] ?? 'Bad request');
      } catch (e) {
        throw const ServerException('Bad request');
      }
    } else {
      AppLogger.error(
        'Server error: ${response.statusCode}',
        null,
        null,
        'ApiClient'
      );
      AppLogger.response('Response body: ${response.body}', 'ApiClient');
      throw ServerException('Server error: ${response.statusCode}');
    }
  }
}