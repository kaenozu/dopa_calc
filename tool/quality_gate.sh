#!/usr/bin/env bash
set -euo pipefail
echo "== dopa_calc quality gate =="
echo "[1/5] flutter pub get"
flutter pub get
echo "[2/5] dart format"
dart format --output=none --set-exit-if-changed lib test
echo "[3/5] flutter analyze"
flutter analyze
echo "[4/5] flutter test"
flutter test
echo "[5/5] flutter build apk --debug (clean checkout verify)"
flutter build apk --debug
echo "== all passed =="
