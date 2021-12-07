import { FileWithRuntime } from 'split-config-generator';
import { FileWithRuntimeDictionary } from '../models';

export function createFilesWithRuntime(
  filesByRuntime: FileWithRuntimeDictionary
): FileWithRuntime[] {
  return Object.entries(filesByRuntime)
    .map(([key, value]) => {
      const { runtime } = value;
      return {
        filePath: removeLeadingDotSlash(key),
        runtime,
      };
    })
    .sort((a, b) => (a.runtime < b.runtime ? 1 : -1));
}

function removeLeadingDotSlash(filePath: string) {
  return filePath.replace(/\.\//, '');
}
