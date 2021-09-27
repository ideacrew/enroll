import {
  FileWithRuntime,
  // FileGroup,
  SplitConfig,
  FilesWithRunTime,
} from '../models';
// import { createGroupOverview } from './createGroupRunTimes';
import { createSplitConfig } from './createSplitConfig';
import { runtimeDetails } from './numberOfGroups';

export function splitFilesIntoGroups(
  files: FileWithRuntime[],
  groupCount: number | undefined
): SplitConfig {
  const { longestTest, longestTestName, totalRuntime, suggestedGroupCount } =
    runtimeDetails(files);

  console.log({
    longestTest: inMinutes(longestTest),
    longestTestName,
    totalRuntime: inMinutes(totalRuntime),
    incomingGroupCount: groupCount ?? 'No provided group count',
    suggestedGroupCount,
  });

  const expectedGroupCount = groupCount ?? suggestedGroupCount;

  const groupRunTimes: FilesWithRunTime[] = Array.from(
    { length: expectedGroupCount },
    () => ({
      files: [],
    })
  );

  // The total runtime of a group is limited based on either:
  // 1. The longest test if the suggested group count is used
  // 2. The total runtime of all the tests divided by the manual group count
  let maxGroupRuntime: number;
  if (groupCount === undefined) {
    maxGroupRuntime = longestTest;
  } else {
    maxGroupRuntime = totalRuntime / expectedGroupCount;
  }

  console.log({ maxGroupRuntime: inMinutes(maxGroupRuntime) });

  if (maxGroupRuntime < longestTest) {
    console.error(`The max group runtime is less than the longest test.`);
    console.error(`Decrease group count or run without a second argument.`);
  }

  // The magic happens here
  groupRunTimes.forEach(async (group) => {
    while (getGroupRunTime(group) < longestTest && files.length) {
      // start with file at front of array
      const largestFile = files[0];

      // test whether that file can be added to current group
      const largestFileIsAddable =
        largestFile.runTime + getGroupRunTime(group) <= longestTest;

      // if that file can be added, add it
      if (largestFileIsAddable) {
        const file = files.shift();
        group.files.push(file);
      }

      if (files.length === 0) {
        break;
      }

      const smallestFile: FileWithRuntime = files[files.length - 1];

      const smallestFileIsAddable =
        smallestFile.runTime + getGroupRunTime(group) <= longestTest;

      if (smallestFileIsAddable) {
        const file = files.pop();
        group.files.push(file);
      } else {
        break;
      }
    }

    // console.log('Group', index + 1, 'has', group.files.length, 'files.');
    // console.log('==================================================');
  });

  // console.log('Files left', files.length);

  // const overview = createGroupOverview(groupRunTimes);
  // console.log(overview);

  const a: SplitConfig = createSplitConfig(groupRunTimes);

  return a;
}

export const getGroupRunTime = (filesWithRunTime: FilesWithRunTime): number => {
  const rawRuntime = filesWithRunTime.files.reduce((runtime, file) => {
    return file ? runtime + file.runTime : 0;
  }, 0);

  // console.log({ rawRuntime: inMinutes(rawRuntime) });

  return rawRuntime;
};

export const inMinutes = (runTime: number): string =>
  `${runTime / 1000 / 60} minutes`;

export const inMinutesNum = (runTime: number): number => runTime / 1000 / 60;
