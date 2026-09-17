import 'package:equatable/equatable.dart';

/// Explicit outcome of an audio deletion operation (single or bulk).
class AudioDeleteResult extends Equatable {
  final List<String> successfulIds;
  final Map<String, String> failedIds; // sessionId -> error message

  const AudioDeleteResult({
    this.successfulIds = const [],
    this.failedIds = const {},
  });

  /// True if all targeted audio deletions succeeded and at least one was deleted.
  bool get isSuccess => failedIds.isEmpty && successfulIds.isNotEmpty;

  /// True if all targeted audio deletions failed.
  bool get isFailure => successfulIds.isEmpty && failedIds.isNotEmpty;

  /// True if some audio deletions succeeded and some failed.
  bool get isPartial => successfulIds.isNotEmpty && failedIds.isNotEmpty;

  /// True if no deletions were performed (e.g. empty target list).
  bool get isEmpty => successfulIds.isEmpty && failedIds.isEmpty;

  /// Total count of deletion operations attempted.
  int get totalAttempted => successfulIds.length + failedIds.length;

  @override
  List<Object?> get props => [successfulIds, failedIds];
}
