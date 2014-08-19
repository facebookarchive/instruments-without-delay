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

#import "../../Common/SwizzleSelector.h"

static NSDictionary *IndigoSessionController_additionalEnvironment(id self, SEL _cmd) {
  NSMutableDictionary *environment = [[self __IndigoSessionController_additionalEnvironment] mutableCopy];
  NSDictionary *currentEnvironment = [[NSProcessInfo processInfo] environment];
  environment[@"DYLD_INSERT_LIBRARIES"] = [NSString stringWithFormat:@"%@/DTMobileISShim.dylib", currentEnvironment[@"LIB_PATH"]];
  environment[@"LIB_PATH"] = currentEnvironment[@"LIB_PATH"];
  return environment;
}

__attribute__((constructor)) static void EntryPoint(void) {
  SwizzleSelectorForFunction(NSClassFromString(@"IndigoSessionController"), @selector(additionalEnvironment), (IMP)IndigoSessionController_additionalEnvironment);

  // Don't cascade into any other programs started.
  unsetenv("DYLD_INSERT_LIBRARIES");
}
