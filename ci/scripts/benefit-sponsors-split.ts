import { promises as fs } from 'fs';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  FileGroup,
} from './models';
import {
  createFileDictionary,
  createFilesWithRuntime,
  splitFilesIntoGroups,
} from './util';
import { runtimeDetails } from './util/numberOfGroups';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments

  const report: string = await fs.readFile(
    './ci/rspec/components-benefit_sponsors-rspec-report.json',
    'utf-8'
  );

  const { examples } = JSON.parse(report);

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary =
    createFileDictionary(examples);

  const arrayOfSlowFiles: FileWithRuntime[] =
    createFilesWithRuntime(filesByRuntime);

  const { suggestedGroupCount } = runtimeDetails(arrayOfSlowFiles);

  console.log('Creating split config');
  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    suggestedGroupCount
  );

  try {
    await fs.writeFile(
      `./ci/benefit_sponsors-split-config.json`,
      JSON.stringify(splitConfig)
    );
  } catch (e) {
    console.error(e);
  }
}

createSplitConfig();
