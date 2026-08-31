#!/usr/bin/env bash
set -euo pipefail
echo "== dopa_calc quality gate =="
echo "[1/4] dart format"
dart format --output=none --set-exit-if-changed lib test
echo "[2/4] flutter analyze"
flutter analyze
echo "[3/4] flutter test"
flutter test
echo "[4/4] flutter build apk --debug (clean checkout verify)"
flutter build apk --debug
echo "== all passed =="
