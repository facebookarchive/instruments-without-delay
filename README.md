- - -

**_This project is not actively maintained. Proceed at your own risk!_**

- - -  

## instruments-without-delay

__instruments-without-delay__ fixes the 1-second delay problem when using `UIAHost.performTaskWithPathArgumentsTimeout` inside of Apple's Instruments / UIAutomation tool.  `performTaskWithPathArgumentsTimeout` would normally take 1 second to respond regardless of how fast the task finishes.

If you're using Instruments to drive UI integration tests (e.g. with [ios-driver](https://github.com/freynaud/ios-driver)), this hack can significantly speed up testing.

__NOTE__: For pre-Xcode 6, build from e4e474c7e9559bfc34724b3338c56b28b3390cd2 as Xcode 6 support introduced breaking changes.


### Usage

Build and run the test:

```
./build.sh test
```

The simulator identifier/name can optionally be added as an argument:

```
./build.sh test D82D8D7B-5253-3300-B083-B6F739F68355
```

Under the `build` directory, you'll have a new `instruments` script.  Use it in place of `/usr/bin/instruments`.

### How it works

Instruments launches UIAutomation scripts in the iOS Simulator with a program called __ScriptAgent__.  Actually, Instruments launches the __iOS Simulator__, which starts up the whole Simulator environment. Eventually, __DTMobileIS__ is started up which finally starts launches __ScriptAgent__.  ScriptAgent is what actually links __UIAutomation.framework__ and runs the scripts, so we inject a library into ScriptAgent that swizzles out `performTaskWithPathArgumentsTimeout` with our own implementation that has no 1 second delay.
