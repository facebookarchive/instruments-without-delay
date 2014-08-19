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


#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <spawn.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <CoreServices/CoreServices.h>

#import "../../Common/dyld-interposing.h"

struct __attribute__ ((__packed__)) LSApplicationParameters_V1 {
  CFIndex version;
  LSLaunchFlags flags;
  id environment;
  id unknown;
  CFArrayRef argv;
};
typedef struct LSApplicationParameters_V1 LSApplicationParameters_V1;

id _LSOpenApplicationURL(NSURL *url, LSLaunchFlags *launchFlags, const LSApplicationParameters_V1 *appParams);
static id __LSOpenApplicationURL(NSURL *url, LSLaunchFlags *launchFlags, LSApplicationParameters_V1 *appParams) {
  if ([[url absoluteString] rangeOfString:@"iOS%20Simulator"].location != NSNotFound) {
    NSMutableDictionary *newEnvironment = [NSMutableDictionary dictionary];
    if (appParams->environment) {
      newEnvironment = [NSMutableDictionary dictionaryWithDictionary:appParams->environment];
    }
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    newEnvironment[@"DYLD_INSERT_LIBRARIES"] = [NSString stringWithFormat:@"%@/SimShim.dylib", environment[@"LIB_PATH"]];
    newEnvironment[@"LIB_PATH"] = environment[@"LIB_PATH"];
    appParams->environment = newEnvironment;
  }
  return _LSOpenApplicationURL(url, launchFlags, appParams);
}

DYLD_INTERPOSE(__LSOpenApplicationURL, _LSOpenApplicationURL);

__attribute__((constructor)) static void EntryPoint()
{
  unsetenv("DYLD_INSERT_LIBRARIES");
}