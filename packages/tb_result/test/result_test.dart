import 'package:result/src/failure.dart';
import 'package:result/src/result.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('success holds data', () {
      const result = Result.success(42);
      expect(result.isSuccess, true);
      expect(result.dataOrNull, 42);
    });

    test('failure holds Failure', () {
      final result = Result<int>.failure(
        Failure(code: 'ERR', message: 'Something went wrong'),
      );
      expect(result.isFailure, true);
      expect(result.failureOrNull?.code, 'ERR');
    });

    test('when routes correctly', () {
      const Result<int> result = Success(10);
      final output = result.when(
        success: (d) => 'got $d',
        failure: (_) => 'failed',
      );
      expect(output, 'got 10');
    });

    test('map transforms success value', () {
      const Result<int> result = Success(5);
      final mapped = result.map((d) => d * 2);
      expect(mapped.dataOrNull, 10);
    });

    test('map preserves failure', () {
      final Result<int> result = Err(Failure(code: 'E', message: 'err'));
      final mapped = result.map((d) => d * 2);
      expect(mapped.isFailure, true);
    });

    test('fromAsync wraps success', () async {
      final result = await Result.fromAsync(() async => 'hello');
      expect(result.dataOrNull, 'hello');
    });

    test('fromAsync catches exception into Failure', () async {
      final result = await Result.fromAsync<int>(
        () async => throw Exception('boom'),
        onError: (e, st) => Failure.unexpected(originalError: e),
      );
      expect(result.isFailure, true);
      expect(result.failureOrNull?.code, 'UNEXPECTED_ERROR');
    });

    test('onSuccess side effect fires', () {
      var called = false;
      const Result<int> result = Success(1);
      result.onSuccess((_) => called = true);
      expect(called, true);
    });

    test('onFailure side effect fires', () {
      var called = false;
      final Result<int> result = Err(Failure(code: 'E', message: 'e'));
      result.onFailure((_) => called = true);
      expect(called, true);
    });
  });
}
