#!/usr/bin/env bash
set -euo pipefail

# Source this file from a normal macOS terminal before running Flutter:
#   source tool/flutter_env.sh
#
# The Codex-hosted shell blocks macOS sysctl calls used by Dart. Running this
# from Terminal/iTerm/VS Code avoids that host restriction.

FLUTTER_SDK="${FLUTTER_SDK:-$HOME/flutter}"
if [[ ! -x "$FLUTTER_SDK/bin/flutter" ]]; then
  echo "Flutter SDK not found at $FLUTTER_SDK" >&2
  echo "Set FLUTTER_SDK to your Flutter installation and source this file again." >&2
  return 1 2>/dev/null || exit 1
fi

export FLUTTER_SDK
export PATH="$FLUTTER_SDK/bin:$PATH"

echo "Flutter: $(command -v flutter)"
flutter --version
