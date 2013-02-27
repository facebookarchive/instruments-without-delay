
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <spawn.h>
#import <mach-o/dyld.h>

#import "../../Common/ArrayOfStrings.h"
#import "../../Common/dyld-interposing.h"

NSString *AbsoluteExecutablePath(void)
{
  char execRelativePath[1024] = {0};
  uint32_t execRelativePathSize = sizeof(execRelativePath);
  
  _NSGetExecutablePath(execRelativePath, &execRelativePathSize);
  
  char execAbsolutePath[1024] = {0};
  assert(realpath((const char *)execRelativePath, execAbsolutePath) != NULL);
  
  return [NSString stringWithUTF8String:execAbsolutePath];
}

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
  unsetenv("DYLD_INSERT_LIBRARIES");
}