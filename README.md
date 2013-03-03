## instruments-without-delay

__instruments-without-delay__ fixes the 1-second delay problem when using `UIAHost.performTaskWithPathArgumentsTimeout` inside of Apple's Instruments / UIAutomation tool.  `performTaskWithPathArgumentsTimeout` would normally take 1 second to respond regardless of how fast the task finishes.

### Usage

Build and run the test:

```
./build.sh test
```

Under the `build` directory, you'll have a new `instruments` script.  Use it in place of `/usr/bin/instruments`.

### How it works

Instruments launches UIAutomation scripts in the iOS Simulator with a program called __ScriptAgent__.  Actually, Instruments launches a small helper program called __sim__, which in turn launches __ScriptAgent__.  ScriptAgent is what actually links __UIAutomation.framework__ and runs the scripts, so we inject a library into ScriptAgent that swizzles out `performTaskWithPathArgumentsTimeout` with our own implementation that has no 1 second delay.
