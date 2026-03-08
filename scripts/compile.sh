#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_DIR="$ROOT_DIR/rtl"
TEST_DIR="$ROOT_DIR/tests"
BUILD_DIR="$ROOT_DIR/build"

mkdir -p "$BUILD_DIR"

command -v iverilog >/dev/null 2>&1 || {
  echo "ERROR: iverilog not found. Install with: sudo apt install iverilog"
  exit 1
}

echo "== Icarus Verilog version =="
iverilog -V
echo

RTL_FILES=("$RTL_DIR"/*.v)

echo "== Compiling all tests (syntax + elaboration check) =="

for testfile in "$TEST_DIR"/*.sv; do
  testname=$(basename "$testfile" .sv)
  echo "-- Checking: $testname"

  iverilog -g2012 \
    -o "$BUILD_DIR/${testname}.out" \
    "$testfile" "${RTL_FILES[@]}"
done

echo
echo "OK: All tests compiled successfully."