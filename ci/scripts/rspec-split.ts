import { promises as fs } from 'fs';
import { runtimeDictionary } from './concat-rspec-reports';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  FileGroup,
} from './models';
import { createFilesWithRuntime, splitFilesIntoGroups } from './util';
import { runtimeDetails } from './util/numberOfGroups';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const [splitConfigPath] = process.argv.slice(2);

  if (splitConfigPath === undefined) {
    console.error('Missing cli arguments');
    process.exit(1);
  }

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary = await runtimeDictionary();

  const arrayOfSlowFiles: FileWithRuntime[] =
    createFilesWithRuntime(filesByRuntime);

  const { suggestedGroupCount } = runtimeDetails(arrayOfSlowFiles);

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    suggestedGroupCount
  );

  try {
    await fs.writeFile(`./${splitConfigPath}`, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createSplitConfig();
