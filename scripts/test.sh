#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <testname>"
  echo "Example: $0 counter-test"
  exit 1
fi

TEST_NAME="$1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_DIR="$ROOT_DIR/rtl"
TEST_DIR="$ROOT_DIR/tests"
BUILD_DIR="$ROOT_DIR/build"
WAVE_DIR="$ROOT_DIR/waveforms"

TEST_FILE="$TEST_DIR/${TEST_NAME}.sv"

if [[ ! -f "$TEST_FILE" ]]; then
  echo "ERROR: Test not found: $TEST_FILE"
  echo
  echo "Available tests:"
  ls -1 "$TEST_DIR"/*.sv 2>/dev/null | sed 's#.*/##' | sed 's/\.sv$//'
  exit 1
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$WAVE_DIR"

RTL_FILES=("$RTL_DIR"/*.v)

OUT_FILE="$BUILD_DIR/${TEST_NAME}.out"

echo "== Compiling $TEST_NAME =="
iverilog -g2012 \
  -o "$OUT_FILE" \
  "$TEST_FILE" "${RTL_FILES[@]}"

echo "== Running $TEST_NAME =="
(
  cd "$BUILD_DIR"
  vvp "${TEST_NAME}.out"
)

# Find generated VCD (assumes TB calls $dumpfile)
VCD_FILE=$(find "$BUILD_DIR" -maxdepth 1 -name "*.vcd" | head -n 1 || true)

if [[ -z "$VCD_FILE" ]]; then
  echo "ERROR: No VCD produced."
  echo "Make sure your testbench calls:"
  echo '  $dumpfile("wave.vcd");'
  echo '  $dumpvars(0, <tb_module_name>);'
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FINAL_VCD="$WAVE_DIR/${TEST_NAME}__${TIMESTAMP}.vcd"

mv "$VCD_FILE" "$FINAL_VCD"

echo
echo "Waveform written to:"
echo "  $FINAL_VCD"
echo
echo "Open with:"
echo "  surfer \"$FINAL_VCD\""
echo "or"
echo "  gtkwave \"$FINAL_VCD\""