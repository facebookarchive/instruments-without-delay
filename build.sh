#!/bin/sh

set -e
cd `dirname $0`

BUILD_OUTPUT_DIR=$(echo `pwd`/build)

xcodebuild \
  -workspace instruments-without-delay.xcworkspace \
  -scheme instruments-without-delay \
  -configuration Release \
  CONFIGURATION_BUILD_DIR=$BUILD_OUTPUT_DIR

cp instruments-without-delay $BUILD_OUTPUT_DIR/instruments-without-delay

if [[ $1 == "test" ]]; then
  TEST_JS=$(echo `pwd`/test.js)
  XCODE_PATH=$(xcode-select --print-path)

  OUTPUT_DIR=$(/usr/bin/mktemp -d -t trace)
  pushd $OUTPUT_DIR
  $BUILD_OUTPUT_DIR/instruments-without-delay \
    -t "$XCODE_PATH"/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate \
    $BUILD_OUTPUT_DIR/TestApp.app \
    -e UIASCRIPT $TEST_JS
  popd
  rm -rf $OUTPUT_DIR
fi
