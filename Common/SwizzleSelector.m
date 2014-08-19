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

#import "SwizzleSelector.h"

#import <objc/runtime.h>
#import <objc/message.h>

void SwizzleSelectorForFunction(Class cls, SEL sel, IMP newImp)
{
  Method originalMethod = class_getInstanceMethod(cls, sel);
  const char *typeEncoding = method_getTypeEncoding(originalMethod);

  NSString *newSelectorName = [NSString stringWithFormat:@"__%s_%s", class_getName(cls), sel_getName(sel)];
  SEL newSelector = sel_registerName([newSelectorName UTF8String]);
  class_addMethod(cls, newSelector, newImp, typeEncoding);

  Method newMethod = class_getInstanceMethod(cls, newSelector);
  method_exchangeImplementations(originalMethod, newMethod);
}