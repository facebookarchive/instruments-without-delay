
#import <spawn.h>
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
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  for (int i = 0; argv[i] != 0; i++) {
    NSString *argStr = [NSString stringWithUTF8String:argv[i]];
    if ([argStr hasSuffix:@"ScriptAgent"]) {
      shouldInsertLib = YES;
    }
  }
  
  BOOL isNotWhich = ![[NSString stringWithUTF8String:path] isEqualToString:@"/usr/bin/which"];
  
  if (isNotWhich && shouldInsertLib) {
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
  [pool release];
  return result;
}
DYLD_INTERPOSE(_posix_spawn, posix_spawn);

__attribute__((constructor)) static void EntryPoint(void);
__attribute__((constructor)) static void EntryPoint(void) {
  unsetenv("DYLD_INSERT_LIBRARIES");
}
