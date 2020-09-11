import { FileWithRuntime } from '../models';

export function groupCount(files: FileWithRuntime[]): number {
  const [longestTest] = files.sort((a, b) => (a.runTime > b.runTime ? -1 : 1));
  const totalRuntime = files.reduce((runtime, file) => {
    return runtime + file.runTime;
  }, 0);

  const suggestedGroupCount = Math.ceil(totalRuntime / longestTest.runTime);
  console.log({
    longestTest: longestTest.runTime,
    totalRuntime,
    suggestedGroupCount,
  });
  return suggestedGroupCount;
}
