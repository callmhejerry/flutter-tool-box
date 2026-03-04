// lib/src/delayed_result/delayed_result_builder.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'delayed_result.dart';
import 'delayed_result_cubit.dart';

/// A Flutter widget that rebuilds based on [DelayedResultCubit] state.
///
/// For screens with multiple independent async states, compose multiple
/// [DelayedResultBuilder] widgets — each only rebuilds when its cubit changes.
///
/// ```dart
/// Column(
///   children: [
///     DelayedResultBuilder<UserCubit, User>(
///       onSuccess: (context, user) => UserHeader(user),
///       onLoading: (_) => const ShimmerHeader(),
///       onError: (context, e, _) => ErrorWidget(e),
///     ),
///     DelayedResultBuilder<PostsCubit, List<Post>>(
///       onSuccess: (context, posts) => PostsList(posts),
///       onLoading: (_) => const PostsShimmer(),
///       onError: (context, e, _) => ErrorWidget(e),
///     ),
///   ],
/// )
/// ```
class DelayedResultBuilder<C extends DelayedResultCubit<T>, T>
    extends StatelessWidget {
  const DelayedResultBuilder({
    super.key,
    required this.onSuccess,
    this.onInitial,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.buildWhen,
  });

  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context)? onInitial;
  final Widget Function(BuildContext context)? onLoading;
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
  onError;
  final Widget Function(BuildContext context)? onEmpty;
  final bool Function(DelayedResult<T> previous, DelayedResult<T> current)?
  buildWhen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, DelayedResult<T>>(
      buildWhen: buildWhen,
      builder: (context, state) => switch (state) {
        DelayedInitial<T>() =>
          onInitial?.call(context) ?? const SizedBox.shrink(),
        DelayedLoading<T>() =>
          onLoading?.call(context) ?? const _DefaultLoading(),
        DelayedError<T>(error: final e, stackTrace: final st) =>
          onError?.call(context, e, st) ?? _DefaultError(error: e),
        DelayedSuccess<T>(data: final d) => onSuccess(context, d),
      },
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive());
}

class _DefaultError extends StatelessWidget {
  final Object error;
  const _DefaultError({required this.error});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      error.toString(),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
