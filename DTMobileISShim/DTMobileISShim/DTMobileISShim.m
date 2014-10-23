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

#import <spawn.h>
#import <sys/uio.h>
#import "../../Common/dyld-interposing.h"
#import "../../Common/ArrayOfStrings.h"

static int _posix_spawn(pid_t *pid,
                        const char *path,
                        const posix_spawn_file_actions_t *file_actions,
                        const posix_spawnattr_t *attrp,
                        char *const argv[],
                        char *const envp[])
{
  int result = 0;
  char **newEnvp = NULL;
  BOOL shouldInsertLib = NO;
  @autoreleasepool {
    for (int i = 0; argv[i] != 0; i++) {
      NSString *argStr = [NSString stringWithUTF8String:argv[i]];
      if ([argStr hasSuffix:@"ScriptAgent"]) {
        shouldInsertLib = YES;
      }
    }

    if (shouldInsertLib) {
      char *addedEnvp[] = {
        (char *)[[NSString stringWithFormat:@"DYLD_INSERT_LIBRARIES=%s/ScriptAgentShim.dylib", getenv("LIB_PATH")] UTF8String],
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
  }
  return result;
}
DYLD_INTERPOSE(_posix_spawn, posix_spawn);

// TODO: Insert giant ASCII clown right here.
// Instruments can't handle writev's of larger than 8KB. We really shouldn't
// be fixing this here but it's way too much effort to bug all the consumers
// and we have to rush for a deadline (classic clowniness).
static ssize_t _writev(int fildes, const struct iovec *iov, int iovcnt)
{
  // Limiting scope here, but the only known case of this for us is when
  // DDLog tries writing larger than 8KB, so let's handle that case.
  if (iovcnt == 2 && iov[0].iov_len >= 8096) {
    struct iovec iovv[2];
    
    iovv[0].iov_base = iov[0].iov_base;
    iovv[0].iov_len = 8096;
    iovv[1].iov_base = iov[1].iov_base;
    iovv[1].iov_len = iov[1].iov_len;
    return writev(fildes, iovv, iovcnt);
  }
  
  return writev(fildes, iov, iovcnt);
}
DYLD_INTERPOSE(_writev, writev);


__attribute__((constructor)) static void EntryPoint(void) {
  // Don't cascade into any other programs started.
  unsetenv("DYLD_INSERT_LIBRARIES");
}