//
// Copyright 2013 Facebook
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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

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
  
  NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:[[NSProcessInfo processInfo] environment]];
  NSString *path = [[NSString stringWithContentsOfFile:@"/etc/paths"
                                              encoding:NSUTF8StringEncoding
                                                 error:NULL]
                          stringByReplacingOccurrencesOfString:@"\n"
                                                    withString:@":"];
  [environment setObject:path
                  forKey:@"PATH"];
  [environment removeObjectForKey:@"DYLD_ROOT_PATH"];
  [task setEnvironment:environment];

  [task launch];
  [task waitUntilExit];
  
  while (standardOutput == nil || standardError == nil) {
    CFRunLoopRun();
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:stdoutObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:stderrObserver];
  
  return @{@"stdout" : standardOutput, @"stderr" : standardError};
}

static void SwizzleSelectorForFunction(Class cls, SEL sel, IMP newImp)
{
  Method originalMethod = class_getInstanceMethod(cls, sel);
  const char *typeEncoding = method_getTypeEncoding(originalMethod);
  
  NSString *newSelectorName = [NSString stringWithFormat:@"__%s_%s", class_getName(cls), sel_getName(sel)];
  SEL newSelector = sel_registerName([newSelectorName UTF8String]);
  class_addMethod(cls, newSelector, newImp, typeEncoding);
  
  Method newMethod = class_getInstanceMethod(cls, newSelector);
  method_exchangeImplementations(originalMethod, newMethod);
}

static id UIAHost_performTaskWithpath(id self, SEL cmd, id path, id arguments, id timeout)
{
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:path];
  [task setArguments:arguments];
  
  NSDictionary *output = LaunchTaskAndCaptureOutput(task);
  
  id result = @{@"exitCode": @([task terminationStatus]),
                @"stdout": output[@"stdout"],
                @"stdout": output[@"stderr"],
                };
  return result;
}

__attribute__((constructor)) static void EntryPoint()
{
  // UIAHost is from UIAutomation.framework
  SwizzleSelectorForFunction(NSClassFromString(@"UIAHost"),
                             @selector(performTaskWithPath:arguments:timeout:),
                             (IMP)UIAHost_performTaskWithpath);
  
  // Don't cascade into any other programs started.
  unsetenv("DYLD_INSERT_LIBRARIES");
}
