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
#import <spawn.h>

#import "../../Common/ArrayOfStrings.h"
#import "../../Common/dyld-interposing.h"

static int _posix_spawn(pid_t *pid,
                        const char *path,
                        const posix_spawn_file_actions_t *file_actions,
                        const posix_spawnattr_t *attrp,
                        char *const argv[],
                        char *const envp[])
{
  int result = 0;
  char **newEnvp = NULL;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // ScriptAgent is an iOS Simulator binary.  Instruments uses a helper program called 'sim'
  // (.../Platforms/iPhoneSimulator.platform/usr/bin/sim) to launch iOS sim binaries.  It seems
  // to handle setting up all the right DYLD_ paths so the iOS versions of libs get used.
  if ([[[NSString stringWithUTF8String:path] lastPathComponent] isEqualToString:@"sim"]) {
    char *addedEnvp[] = {
      (char *)[[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%s/SimLib.dylib", getenv("LIB_PATH")] UTF8String],
      (char *)[[NSString stringWithFormat:@"LIB_PATH=%s", getenv("LIB_PATH")] UTF8String],
      NULL,
    };
    
    newEnvp = ArrayOfStringsByAppendingStrings(envp, addedEnvp);
    
    result = posix_spawn(pid, path, file_actions, attrp, argv, newEnvp);
  } else {
    result = posix_spawn(pid, path, file_actions, attrp, argv, envp);
  }
  
Error:
  if (newEnvp != NULL) {
    FreeArrayOfStrings(newEnvp);
  }
  [pool release];
  return result;
}
DYLD_INTERPOSE(_posix_spawn, posix_spawn);

__attribute__((constructor)) static void EntryPoint()
{
  // Don't cascade into any other programs started.
  unsetenv("DYLD_INSERT_LIBRARIES");
}