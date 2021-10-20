import { promises as fs } from 'fs';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  FileGroup,
  RspecExample,
} from './models';

import {
  createFileDictionary,
  createFilesWithRuntime,
  splitFilesIntoGroups,
} from './util';

const REPORT_PATH = './ci/rspec/local-rspec-report.json';
const SPLIT_CONFIG_PATH = './ci/rspec-split-config.json';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const rspecExamples = await fs.readFile(REPORT_PATH, 'utf-8');
  const examples: RspecExample[] = JSON.parse(rspecExamples);

  const [manualGroupCountInput] = process.argv.slice(2);

  const groupCount: number | undefined =
    manualGroupCountInput !== undefined
      ? parseInt(manualGroupCountInput, 10)
      : undefined;

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary =
    createFileDictionary(examples);

  const arrayOfSlowFiles: FileWithRuntime[] =
    createFilesWithRuntime(filesByRuntime);

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    groupCount
  );

  try {
    await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createSplitConfig();
