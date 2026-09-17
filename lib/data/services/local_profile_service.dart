import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Resolves isolated, device-local storage paths per authenticated user.
class LocalProfileService {
  final String baseDirectory;

  const LocalProfileService(this.baseDirectory);

  /// Converts an arbitrary user ID into a deterministic, filesystem-safe segment.
  ///
  /// Uses hexadecimal encoding of UTF-8 bytes to ensure the resulting segment
  /// contains only ASCII hex characters `[0-9a-f]`, preventing any directory
  /// traversal or invalid path characters.
  static String encodeUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID must not be empty.');
    }
    return utf8
        .encode(userId)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Resolves and ensures the isolated root directory for [userId].
  ///
  /// Never logs or exposes user IDs or file paths.
  Future<String> resolveProfileRoot(String userId) async {
    final encoded = encodeUserId(userId);
    final profilePath = p.join(baseDirectory, 'profiles', encoded);
    await Directory(profilePath).create(recursive: true);
    return profilePath;
  }

  /// Checks whether a profile directory already exists for [userId].
  Future<bool> profileExists(String userId) async {
    final encoded = encodeUserId(userId);
    final profilePath = p.join(baseDirectory, 'profiles', encoded);
    return Directory(profilePath).exists();
  }
}
