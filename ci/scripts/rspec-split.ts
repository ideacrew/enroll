import { promises as fs } from 'fs';
import { runtimeDictionary } from './concat-rspec-reports';

import {
  FileWithRuntime,
  FileWithRuntimeDictionary,
  FileGroup,
} from './models';
import { createFilesWithRuntime, splitFilesIntoGroups } from './util';

async function createSplitConfig(): Promise<void> {
  // Read cli arguments
  const [splitConfigPath, manualGroupCount] = process.argv.slice(2);

  if (splitConfigPath === undefined || manualGroupCount === undefined) {
    console.error('Missing cli arguments');
    process.exit(1);
  }

  // Create a dictionary of
  const filesByRuntime: FileWithRuntimeDictionary = await runtimeDictionary();

  const arrayOfSlowFiles: FileWithRuntime[] =
    createFilesWithRuntime(filesByRuntime);

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    parseInt(manualGroupCount, 10)
  );

  try {
    await fs.writeFile(`./${splitConfigPath}`, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createSplitConfig();
