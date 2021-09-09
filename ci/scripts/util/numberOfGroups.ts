import { FileWithRuntime } from '../models';

/**
 * Reads file array and returns details about the
 * nature of the set of files
 * @param files an array of files with runtime
 */
export function runtimeDetails(files: FileWithRuntime[]) {
  const [longestTest] = files.sort((a, b) => (a.runTime > b.runTime ? -1 : 1));
  const totalRuntime = files.reduce((runtime, file) => {
    // console.log(runtime);
    return runtime + file.runTime;
  }, 0);

  const suggestedGroupCount = Math.ceil(totalRuntime / longestTest.runTime);

  return {
    longestTest: longestTest.runTime,
    longestTestName: longestTest.filePath,
    totalRuntime,
    suggestedGroupCount,
  };
}
