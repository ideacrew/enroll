import { promises as fs } from 'fs';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  RspecExample,
  SplitConfig,
} from './models';
import {
  createFilesWithRuntime,
  splitFilesIntoGroups,
  createFileDictionary,
} from './util';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const [filePath, numberOfGroups, outputPath] = process.argv.slice(2);

  if (
    filePath === undefined ||
    numberOfGroups === undefined ||
    outputPath === undefined
  ) {
    throw new Error('Please provide the required cli arguments.');
  }

  // Read in rspec report
  const rspecReport = await fs.readFile(`./${filePath}`, 'utf-8');

  // Convert string to workable object
  const examples: RspecExample[] = JSON.parse(rspecReport);

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary = createFileDictionary(
    examples
  );

  const arrayOfSlowFiles: FileWithRuntime[] = createFilesWithRuntime(
    filesByRuntime
  );

  const splitConfig: SplitConfig[] = splitFilesIntoGroups(
    +numberOfGroups, // comes in as a string, need to coerce into a number
    arrayOfSlowFiles
  );

  // await fs.writeFile(`./${outputPath}/rspec-split-config.json`, JSON.stringify(splitConfig));
}

createSplitConfig();
