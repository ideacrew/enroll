export interface FileWithRuntimeDictionary {
  [filePath: string]: {
    runTime: number;
  };
}

export interface FileWithRuntime {
  filePath: string;
  runTime: number;
}