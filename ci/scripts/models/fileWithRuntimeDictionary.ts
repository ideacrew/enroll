export interface FileWithRuntimeDictionary {
  [filePath: string]: {
    runtime: number;
  };
}
