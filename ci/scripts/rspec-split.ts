import { promises as fs } from 'fs';
import {
  createSplitConfig,
  FileWithRuntime,
  SplitConfig,
} from 'split-config-generator';

import { FileWithRuntimeDictionary, RspecExample } from './models';

import { createFileDictionary, createFilesWithRuntime } from './util';

const REPORT_PATH = './ci/rspec/local-rspec-report.json';
const SPLIT_CONFIG_PATH = './ci/rspec-split-config.json';

async function createRspecSplitConfig(): Promise<void> {
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

  const splitConfig: SplitConfig = createSplitConfig(
    arrayOfSlowFiles,
    groupCount
  );

  try {
    await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createRspecSplitConfig();
