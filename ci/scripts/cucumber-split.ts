const { promises: fs } = require('fs');

import { FileWithRuntime, FileGroup } from './models';
import { CucumberFeature } from './models';
import { splitFilesIntoGroups } from './util';
import { featureRuntime } from './util/featureRuntime';

const REPORT_PATH = './ci/cucumber/local-cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

async function createCucumberSplitConfig(): Promise<void> {
  const [manualGroupCount] = process.argv.slice(2);

  if (manualGroupCount === undefined) {
    console.error('Please provide the required cli arguments.');
    process.exit(1);
  }

  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  // Generate list of slow files
  const arrayOfSlowFiles: FileWithRuntime[] = report
    .map(featureRuntime)
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  // console.log('arrayOfSlowFiles', arrayOfSlowFiles.length, arrayOfSlowFiles);

  const splitConfig: FileGroup[] = splitFilesIntoGroups(
    arrayOfSlowFiles,
    +manualGroupCount
  );

  await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
}

createCucumberSplitConfig();
