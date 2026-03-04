// lib/src/client/upload_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:result/result.dart';
import '../exceptions/exception_mapper.dart';
import '../exceptions/network_exception.dart';
import 'dio_client.dart';

/// Handles multipart file uploads with progress tracking.
///
/// Mixin this into your repository or use it standalone.
///
/// ```dart
/// final uploader = UploadService(client: dioClient);
///
/// final result = await uploader.uploadFile(
///   path: '/users/avatar',
///   file: imageFile,
///   fileField: 'avatar',
///   onProgress: (sent, total) {
///     final percent = (sent / total * 100).toStringAsFixed(1);
///     print('Upload: $percent%');
///   },
/// );
/// ```
class UploadService {
  final DioClient client;

  const UploadService({required this.client});

  /// Upload a single file
  Future<Result<T>> uploadFile<T>({
    required String path,
    required File file,
    String fileField = 'file',
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParameters,
    void Function(int sent, int total)? onProgress,
    T Function(dynamic json)? fromJson,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(file.path, filename: fileName),
        if (fields != null) ...fields,
      });

      final response = await client.dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: onProgress,
      );

      final data = fromJson != null ? fromJson(response.data) : response.data;
      return Result.success(data as T);
    } on DioException catch (e) {
      final networkException = ExceptionMapper.fromDioException(e);
      return Result.failure(ExceptionMapper.toFailure(networkException));
    } catch (e, st) {
      return Result.failure(
        ExceptionMapper.toFailure(
          UnexpectedException(originalError: e, stackTrace: st),
        ),
      );
    }
  }

  /// Upload multiple files in one request
  Future<Result<T>> uploadMultipleFiles<T>({
    required String path,
    required List<File> files,
    String fileField = 'files',
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParameters,
    void Function(int sent, int total)? onProgress,
    T Function(dynamic json)? fromJson,
    CancelToken? cancelToken,
  }) async {
    try {
      final multipartFiles = await Future.wait(
        files.map(
          (f) =>
              MultipartFile.fromFile(f.path, filename: f.path.split('/').last),
        ),
      );

      final formData = FormData.fromMap({
        fileField: multipartFiles,
        if (fields != null) ...fields,
      });

      final response = await client.dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
      );

      final data = fromJson != null ? fromJson(response.data) : response.data;
      return Result.success(data as T);
    } on DioException catch (e) {
      final networkException = ExceptionMapper.fromDioException(e);
      return Result.failure(ExceptionMapper.toFailure(networkException));
    } catch (e, st) {
      return Result.failure(
        ExceptionMapper.toFailure(
          UnexpectedException(originalError: e, stackTrace: st),
        ),
      );
    }
  }
}
