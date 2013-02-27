
#import "ArrayOfStrings.h"

char **ArrayOfStringsByAppendingStrings(char *const arr[], char *const arrToAdd[])
{
  int arrCount = 0;
  int arrToAddCount = 0;

  char **newArr = NULL;
  int offset = 0;
  
  for (int i = 0; arr != NULL && arr[i] != NULL; i++) {
    arrCount++;
  }
  
  for (int i = 0; arrToAdd != NULL && arrToAdd[i] != NULL; i++) {
    arrToAddCount++;
  }
  
  newArr = calloc(arrCount + arrToAddCount + 1, sizeof(char *));
  
  // copy in the existing ones
  for (int i = 0; arr != NULL && arr[i] != NULL; i++) {
    newArr[offset] = calloc(strlen(arr[i]) + 1, sizeof(char));
    strcpy(newArr[offset], arr[i]);
    offset++;
  }
  
  // copy in the new ones
  for (int i = 0; arrToAdd != NULL && arrToAdd[i] != NULL; i++) {
    newArr[offset] = calloc(strlen(arrToAdd[i]) + 1, sizeof(char));
    strcpy(newArr[offset], arrToAdd[i]);
    offset++;
  }
  
  newArr[offset] = NULL;
  
  return newArr;
}

void FreeArrayOfStrings(char **envp)
{
  for (int i = 0; envp[i] != NULL; i++) {
    free(envp[i]);
  }
  free(envp);
}
