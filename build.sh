#!/bin/sh

set -e
cd `dirname $0`

BUILD_OUTPUT_DIR=$(echo `pwd`/build)

# We're using a hack to trick ScriptAgentShim into building as a dylib for
# the iOS simulator.  Part of that requires us to specify paths to the
# SDK dirs ourselves and so we need to know the version numbers for the
# newest installed SDK.  See ScriptAgentShim.xcconfig for more info.
_IOS_SDK_VERSION=$(xcodebuild -showsdks | grep iphonesimulator | \
  tail -n 1 | perl -ne '/iphonesimulator(.*?)$/ && print $1')
_IOS_SDK_VERSION_EXPANDED=$(xcodebuild -showsdks | grep iphonesimulator | \
  tail -n 1 | perl -ne '/iphonesimulator(\d)\.(\d)$/ && print "${1}${2}000"')

xcodebuild \
  -workspace instruments-without-delay.xcworkspace \
  -scheme instruments-without-delay \
  -configuration Release \
  CONFIGURATION_BUILD_DIR=$BUILD_OUTPUT_DIR \
  _IOS_SDK_VERSION=$_IOS_SDK_VERSION \
  _IOS_SDK_VERSION_EXPANDED=$_IOS_SDK_VERSION_EXPANDED

cp instruments $BUILD_OUTPUT_DIR/instruments

if [[ $1 == "test" ]]; then
  TEST_JS=$(echo `pwd`/test.js)
  XCODE_PATH=$(xcode-select --print-path)

  OUTPUT_DIR=$(/usr/bin/mktemp -d -t trace)
  pushd $OUTPUT_DIR
  $BUILD_OUTPUT_DIR/instruments \
    -t "$XCODE_PATH"/../Applications/Instruments.app/Contents/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate \
    $BUILD_OUTPUT_DIR/TestApp.app \
    -e UIASCRIPT $TEST_JS
  popd
  rm -rf $OUTPUT_DIR
fi
