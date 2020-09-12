import { FileWithRuntime, SplitConfig } from '../models';
import { groupCount } from './numberOfGroups';

export function splitFilesIntoGroups(files: FileWithRuntime[]): SplitConfig[] {
  const { longestTest, totalRuntime, suggestedGroupCount } = groupCount(files);

  console.log(
    'Splitting',
    files.length,
    'files into',
    suggestedGroupCount,
    'groups, each being no longer than',
    Math.floor(longestTest),
    'milliseconds long.'
  );

  let split: SplitConfig[] = [];

  let bucketTimes = Array.from({ length: suggestedGroupCount }, () => ({
    runTime: 0,
  }));

  let bucket = 0;

  for (let file of files) {
    const currentBucketTime = bucketTimes[bucket].runTime;

    if (currentBucketTime + file.runTime <= longestTest) {
      split[bucket] =
        split[bucket] === undefined
          ? { files: [file.filePath] }
          : { files: [...split[bucket].files, file.filePath] };

      bucketTimes[bucket].runTime += file.runTime;
    } else {
      // console.log(file.filePath, 'is too large to go into bucket', bucket);
      if (bucket < suggestedGroupCount - 1) {
        bucket += 1;
      }
      split[bucket] =
        split[bucket] === undefined
          ? { files: [file.filePath] }
          : { files: [...split[bucket].files, file.filePath] };
      bucketTimes[bucket].runTime += file.runTime;
    }
  }

  console.log(bucketTimes);
  console.log(
    'Groups created. Total runtime should be no greater than',
    longestTest / 1000 / 60,
    'minutes long.'
  );

  return split;
}
