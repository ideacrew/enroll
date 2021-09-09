import { FilesWithRunTime, FileWithRuntime, SplitConfig } from '../models';

export const createSplitConfig = (
  groupRunTimes: FilesWithRunTime[]
): SplitConfig => {
  return groupRunTimes.map((group) => {
    return {
      files: group.files.map((file) => (file as FileWithRuntime).filePath),
    };
  });
};
