import { FileWithRuntimeDictionary, RspecExample } from '../models';

export function createFileDictionary(
  examples: RspecExample[]
): FileWithRuntimeDictionary {
  const dictionary = examples.reduce(
    (totalConfig: FileWithRuntimeDictionary, example: RspecExample) => {
      const filePath = example.file_path;

      if (totalConfig[filePath] !== undefined) {
        const currentTotal = totalConfig[filePath].runTime;

        return {
          ...totalConfig,
          [filePath]: { runTime: currentTotal + example.run_time },
        };
      } else {
        return {
          ...totalConfig,
          [filePath]: { runTime: example.run_time },
        };
      }
    },
    {}
  );

  return dictionary;
}
