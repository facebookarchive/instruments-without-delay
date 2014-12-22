//
// Copyright 2014 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "../../Common/dyld-interposing.h"
#import "../../Common/SwizzleSelector.h"
#import <Foundation/Foundation.h>

// NSTask isn't public in the iOS version of the headers, so we include it here.
@interface NSTask : NSObject
- (void)setLaunchPath:(NSString *)path;
- (void)setArguments:(NSArray *)arguments;
- (void)setEnvironment:(NSDictionary *)dict;
- (void)setStandardInput:(id)input;
- (void)setStandardOutput:(id)output;
- (void)setStandardError:(id)error;
- (NSString *)launchPath;
- (NSArray *)arguments;
- (NSDictionary *)environment;
- (NSString *)currentDirectoryPath;
- (id)standardInput;
- (id)standardOutput;
- (id)standardError;
- (void)launch;
- (void)interrupt;
- (void)terminate;
- (BOOL)suspend;
- (BOOL)resume;
- (int)processIdentifier;
- (BOOL)isRunning;
- (int)terminationStatus;
- (void)waitUntilExit;
@end

static NSDictionary *LaunchTaskAndCaptureOutput(NSTask *task) {
  NSPipe *stdoutPipe = [NSPipe pipe];
  NSFileHandle *stdoutHandle = [stdoutPipe fileHandleForReading];
  
  NSPipe *stderrPipe = [NSPipe pipe];
  NSFileHandle *stderrHandle = [stderrPipe fileHandleForReading];
  
  __block NSString *standardOutput = nil;
  __block NSString *standardError = nil;
  
  void (^completionBlock)(NSNotification *) = ^(NSNotification *notification){
    NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (notification.object == stdoutHandle) {
      standardOutput = str;
    } else if (notification.object == stderrHandle) {
      standardError = str;
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
  };
  
  id stdoutObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification
                                                                        object:stdoutHandle
                                                                         queue:nil
                                                                    usingBlock:completionBlock];
  id stderrObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleReadToEndOfFileCompletionNotification
                                                                        object:stderrHandle
                                                                         queue:nil
                                                                    usingBlock:completionBlock];
  [stdoutHandle readToEndOfFileInBackgroundAndNotify];
  [stderrHandle readToEndOfFileInBackgroundAndNotify];
  [task setStandardOutput:stdoutPipe];
  [task setStandardError:stderrPipe];
  
  [task launch];
  [task waitUntilExit];
  
  while (standardOutput == nil || standardError == nil) {
    CFRunLoopRun();
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:stdoutObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:stderrObserver];
  
  return @{@"stdout" : standardOutput, @"stderr" : standardError};
}

static id UIAHost_performTaskWithPath(id self, SEL cmd, id path, id arguments, id timeout)
{
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:path];
  [task setArguments:arguments];
  
  NSMutableDictionary *environment = [[[NSMutableDictionary alloc] initWithDictionary:[[NSProcessInfo processInfo] environment]] autorelease];
  NSString *envpath = [[NSString stringWithContentsOfFile:@"/etc/paths"
                                                 encoding:NSUTF8StringEncoding
                                                    error:NULL]
                          stringByReplacingOccurrencesOfString:@"\n"
                                                    withString:@":"];
  [environment setObject:envpath
                  forKey:@"PATH"];
  [environment removeObjectForKey:@"DYLD_ROOT_PATH"];
  [task setEnvironment:environment];

  NSDictionary *output = LaunchTaskAndCaptureOutput(task);
  
  id result = @{@"exitCode": @([task terminationStatus]),
                @"stdout": output[@"stdout"],
                @"stderr": output[@"stderr"],
                };
  return result;
}

// This swizzle is to fix the `UIATarget.localTarget().deactivateAppForDuration(..)` API.
// Apple's implementation backgrounds the app and then makes sure that SpringBoard is active.
// Before checking the current pid, it waits a second which is not long enough for the pid to change.
// But, it is long enough to reactivate the app, so we assume the call succeeds.
static BOOL UIATarget_deactivateApp(id self, SEL _cmd) {
  [self __UIATarget_deactivateApp];
  return YES;
}

// This swizzle is make ScriptAgent way faster, as each call to its logger does a [NSUserDefaults boolForKey:]
// which in aggregate, takes a bunch of time. (rdar://18062172)
static BOOL NSUserDefaults_boolForKey(id self, SEL _cmd, NSString *key) {
  if ([key isEqualToString:@"Verbose"] || [key isEqualToString:@"Debug"] || [key isEqualToString:@"Bridge"]) {
    return NO;
  }

  return [self __NSUserDefaults_boolForKey:key];
}

static BOOL UIATarget_tapRequiredObject(id self, SEL _cmd, id object, double tapCount, double touchCount) {
  for (int i=0; i<5; i++) {
    BOOL success = [self __UIATarget__tapRequiredObject:object tapCount:tapCount touchCount:touchCount];
    
    if (success) {
      return YES;
    }
    
    NSLog(@"Delaying due to failed tapRequiredObject: iteration %i", i);
    [self delayForTimeInterval:0.1];
  }
  return NO;
}

__attribute__((constructor)) static void EntryPoint()
{
  //NSLog(@"Built at %s %s", __DATE__, __TIME__);

  SwizzleSelectorForFunction(NSClassFromString(@"UIAHost"),
                             @selector(performTaskWithPath:arguments:timeout:),
                             (IMP)UIAHost_performTaskWithPath);

  SwizzleSelectorForFunction(NSClassFromString(@"UIATarget"), @selector(deactivateApp), (IMP)UIATarget_deactivateApp);

  SwizzleSelectorForFunction(NSClassFromString(@"NSUserDefaults"), @selector(boolForKey:), (IMP)NSUserDefaults_boolForKey);
  
  SwizzleSelectorForFunction(NSClassFromString(@"UIATarget"), @selector(_tapRequiredObject:tapCount:touchCount:), (IMP)UIATarget_tapRequiredObject);

  // Don't cascade into any other programs started.
  unsetenv("DYLD_INSERT_LIBRARIES");
}
