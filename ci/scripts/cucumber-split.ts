const { promises: fs } = require('fs');

import { FileWithRuntime, FileGroup } from './models';
import { CucumberFeature } from './models';
import { splitFilesIntoGroups } from './util';
import { featureRuntime } from './util/featureRuntime';
import { runtimeDetails } from './util/numberOfGroups';

const REPORT_PATH = './ci/cucumber/local-cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

async function createCucumberSplitConfig(): Promise<void> {
  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  // Generate list of slow files
  const arrayOfSlowFiles: FileWithRuntime[] = report
    .map(featureRuntime)
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  // Map file runtimes from nanoseconds to seconds
  const slowFiles: FileWithRuntime[] = arrayOfSlowFiles.map((file) => {
    return {
      filePath: file.filePath,
      runTime: file.runTime / 1000000,
    };
  });

  const { suggestedGroupCount } = runtimeDetails(slowFiles);

  console.log({ slowFiles: slowFiles[0] });

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    slowFiles,
    suggestedGroupCount
  );

  await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
}

createCucumberSplitConfig();
