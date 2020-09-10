import { FileWithRuntime, FileWithRuntimeDictionary } from '../models';

export function createFilesWithRuntime(
  filesByRuntime: FileWithRuntimeDictionary
): FileWithRuntime[] {
  return Object.entries(filesByRuntime)
    .map(([key, value]) => ({
      filePath: removeLeadingDotSlash(key),
      ...value,
    }))
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));
}

function removeLeadingDotSlash(filePath: string) {
  return filePath.replace(/\.\//, '');
}
