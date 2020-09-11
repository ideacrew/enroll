import { FileWithRuntime, SplitConfig } from '../models';
import { groupCount } from './numberOfGroups';

export function splitFilesIntoGroups(
  numberOfGroups: number,
  files: FileWithRuntime[]
  // targetRuntimePerGroup: number
): SplitConfig[] {
  const totalRuntime = files.reduce((runtime, file) => {
    return runtime + file.runTime;
  }, 0);
  const targetRuntimePerGroup = Math.floor(totalRuntime / +numberOfGroups);

  console.log(
    'Splitting',
    files.length,
    'files into',
    numberOfGroups,
    'groups, each being around',
    Math.floor(targetRuntimePerGroup / 1000 / 60),
    'minutes long.'
  );

  groupCount(files);

  // console.log(files.map((file) => file.runTime).slice(0, 10));
  let split: SplitConfig[] = [];

  let bucketTimes = Array.from({ length: numberOfGroups }, () => ({
    runTime: 0,
  }));

  let bucket = 0;

  for (let file of files) {
    const currentBucketTime = bucketTimes[bucket].runTime;

    if (currentBucketTime + file.runTime < targetRuntimePerGroup) {
      split[bucket] =
        split[bucket] === undefined
          ? { files: [file.filePath] }
          : { files: [...split[bucket].files, file.filePath] };

      bucketTimes[bucket].runTime += file.runTime;
    } else {
      // console.log(file.filePath, 'is too large to go into bucket', bucket);
      if (bucket < numberOfGroups - 1) {
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

  return split;
}
