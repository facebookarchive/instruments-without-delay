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
