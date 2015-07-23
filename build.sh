#!/bin/sh

set -e
cd `dirname $0`

BUILD_OUTPUT_DIR=$(echo `pwd`/build)

xcodebuild \
  -workspace instruments-without-delay.xcworkspace \
  -scheme ios-dylibs \
  -configuration Release \
  -sdk iphonesimulator \
  CONFIGURATION_BUILD_DIR=$BUILD_OUTPUT_DIR

xcodebuild \
  -workspace instruments-without-delay.xcworkspace \
  -scheme instruments-without-delay \
  -configuration Release \
  CONFIGURATION_BUILD_DIR=$BUILD_OUTPUT_DIR

cp instruments $BUILD_OUTPUT_DIR/instruments

if [[ $1 == "test" ]]; then
  TEST_JS=$(echo `pwd`/test.js)
  XCODE_PATH=$(xcode-select --print-path)
  OUTPUT_DIR=$(/usr/bin/mktemp -d -t trace)
  if [[ -n $2 ]]; then
    SIMULATOR_NAME="$2"
  else
    SIMULATOR_NAME="iPhone 5 (8."
  fi

  pushd $OUTPUT_DIR
  $BUILD_OUTPUT_DIR/instruments \
    -t "$XCODE_PATH"/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.*/Contents/Resources/Automation.tracetemplate \
    -w $SIMULATOR_NAME \
    $BUILD_OUTPUT_DIR/TestApp.app \
    -e UIASCRIPT $TEST_JS
  popd
  rm -rf $OUTPUT_DIR
fi
