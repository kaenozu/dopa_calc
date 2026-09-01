#!/usr/bin/env bash
set -euo pipefail
echo "== dopa_calc quality gate =="
echo "[1/6] flutter pub get"
flutter pub get
echo "[2/6] git diff --check"
git diff --check
echo "[3/6] dart format"
dart format --output=none --set-exit-if-changed lib test
echo "[4/6] flutter analyze"
flutter analyze
echo "[5/6] flutter test"
flutter test
echo "[6/6] flutter build apk --debug (clean checkout verify)"
flutter build apk --debug
echo "== all passed =="
