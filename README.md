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

### Xcode 7 / iOS 9 Support
As of the time of writing, `SimShim.dylib` can't be injected into the Xcode 7 ```Simulator.app``` as there is kernel-level protection for using `DYLD_INSERT_LIBRARIES` on unsigned binaries. See [this Gist](https://gist.github.com/lawrencelomax/27bdc4e8a433a601008f) for more information. The current workaround is to inject environment variables into the `DTServiceHub` process, by using an `EnvironmentVariables` dictionary in the `com.apple.instruments.deviceservice.plist` Launch Agent. The `LIB_PATH` and `DYLD_INSERT_LIBRARIES` environment variables can be passed through here.
