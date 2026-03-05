// lib/src/client/download_service.dart

import 'package:dio/dio.dart';
import 'package:tb_result/tb_result.dart';
import '../exceptions/exception_mapper.dart';
import '../exceptions/network_exception.dart';
import 'dio_client.dart';

/// Handles file downloads with progress tracking.
///
/// ```dart
/// final downloader = DownloadService(client: dioClient);
///
/// final result = await downloader.downloadFile(
///   url: 'https://example.com/file.pdf',
///   savePath: '/storage/emulated/0/Download/file.pdf',
///   onProgress: (received, total) {
///     if (total != -1) {
///       final percent = (received / total * 100).toStringAsFixed(1);
///       print('Download: $percent%');
///     }
///   },
/// );
/// ```
class DownloadService {
  final DioClient client;

  const DownloadService({required this.client});

  /// Download a file to [savePath]
  ///
  /// Returns [Result<String>] where the String is the [savePath]
  /// on success, so callers know where the file was saved.
  Future<Result<String>> downloadFile({
    required String url,
    required String savePath,
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    Options? options,
    bool deleteOnError = true,
  }) async {
    try {
      await client.dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        options: options,
        onReceiveProgress: onProgress,
      );

      return Result.success(savePath);
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

  /// Download file to memory as bytes (no disk write)
  Future<Result<List<int>>> downloadBytes({
    required String url,
    Map<String, dynamic>? queryParameters,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get<List<int>>(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        options: Options(responseType: ResponseType.bytes),
      );

      return Result.success(response.data!);
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
