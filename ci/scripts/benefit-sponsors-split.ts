import { promises as fs } from 'fs';
import { runtimeDictionary } from './concat-rspec-reports';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  FileGroup,
  RspecReport,
} from './models';
import {
  createFileDictionary,
  createFilesWithRuntime,
  splitFilesIntoGroups,
} from './util';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const [manualGroupCount] = process.argv.slice(2);

  if (manualGroupCount === undefined) {
    console.error('Missing cli arguments');
    process.exit(1);
  }

  const report: string = await fs.readFile(
    './ci/engines/benefit-sponsors/benefit-sponsors-report.json',
    'utf-8'
  );

  const { examples } = JSON.parse(report);

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary = createFileDictionary(
    examples
  );

  const arrayOfSlowFiles: FileWithRuntime[] = createFilesWithRuntime(
    filesByRuntime
  );

  console.log('Creating split config');
  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    +manualGroupCount
  );

  try {
    await fs.writeFile(
      `./ci/engines/benefit-sponsors/rspec-split-config.json`,
      JSON.stringify(splitConfig)
    );
  } catch (e) {
    console.error(e);
  }
}

createSplitConfig();
