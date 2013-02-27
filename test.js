var target = UIATarget.localTarget();
var host = target.host();

var start = new Date().getTime();
// Without this hack, performTask would take a minimum of 1 second to run even
// though echo returns immediately.
var result = host.performTaskWithPathArgumentsTimeout("/bin/echo", ["Hello!"], 5);
var stop = new Date().getTime();

output = result.stdout.trim();
wasFast = (stop - start) < 500;

UIALogger.logDebug("-----------------------------------------");

if (output == 'Hello!' && wasFast) {
  UIALogger.logDebug("PASSED: Got expected output in " + (stop - start) + "ms.");
} else if (output == 'Hello!' && !wasFast) {
  UIALogger.logDebug("FAILED: Got expected output, but it took " + (stop - start) + "ms.");
} else {
  UIALogger.logDebug("FAILED: Didn't get expected output.");
}

UIALogger.logDebug("-----------------------------------------");
