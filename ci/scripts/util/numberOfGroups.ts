import { FileWithRuntime } from 'split-config-generator';

/**
 * Reads file array and returns details about the
 * nature of the set of files
 * @param files an array of files with runtime
 */
export function runtimeDetails(files: FileWithRuntime[]) {
  const [longestTest] = files.sort((a, b) => (a.runtime > b.runtime ? -1 : 1));
  const totalRuntime = files.reduce((runtime, file) => {
    // console.log(runtime);
    return runtime + file.runtime;
  }, 0);

  const suggestedGroupCount = Math.ceil(totalRuntime / longestTest.runtime);

  return {
    longestTest: longestTest.runtime,
    longestTestName: longestTest.filePath,
    totalRuntime,
    suggestedGroupCount,
  };
}
