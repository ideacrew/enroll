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

  const shortenedPaths: FileWithRuntime[] = arrayOfSlowFiles.map((file) => {
    // This removes the `components/benefit_sponsors` from the path
    const shortenedFilePath = file.filePath.substring(28);

    const fileWithRuntime: FileWithRuntime = {
      filePath: shortenedFilePath,
      runTime: file.runTime,
    };

    return fileWithRuntime;
  });

  const { suggestedGroupCount } = runtimeDetails(shortenedPaths);

  console.log('Creating split config');
  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    shortenedPaths,
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
