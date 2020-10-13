import {
  FileWithRuntime,
  FileGroup,
  SplitConfig,
  FilesWithRunTime,
} from '../models';
import { runtimeDetails } from './numberOfGroups';

export function splitFilesIntoGroups(
  files: FileWithRuntime[],
  groupCount: number
): SplitConfig {
  const { longestTest, totalRuntime, suggestedGroupCount } = runtimeDetails(
    files
  );

  const bucketMaxRunTime = Math.floor(totalRuntime / groupCount);

  console.log({ longestTest, totalRuntime, bucketMaxRunTime, groupCount });

  const groups: FileGroup[] = Array.from({ length: groupCount }, () => ({
    files: [],
  }));

  const groupRunTimes: FilesWithRunTime[] = Array.from(
    { length: groupCount },
    () => ({
      files: [],
    })
  );

  for (const group of groupRunTimes) {
    console.log('Files left to process', files.length);
  }

  const a: SplitConfig = groupRunTimes.map((group) => {
    return {
      files: group.files.map((file) => (file as FileWithRuntime).filePath),
    };
  });

  return a;
}

function getGroupRunTime(filesWithRunTime: FilesWithRunTime): number {
  return Math.floor(
    filesWithRunTime.files.reduce((runtime, file) => {
      return file ? runtime + file?.runTime : 0;
    }, 0)
  );
}
