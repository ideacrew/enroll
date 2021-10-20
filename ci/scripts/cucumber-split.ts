const { promises: fs } = require('fs');

import { FileWithRuntime, FileGroup } from './models';
import { CucumberFeature } from './models';
import { splitFilesIntoGroups } from './util';
import { featureRuntime } from './util/featureRuntime';

const REPORT_PATH = './ci/cucumber/local-cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

async function createCucumberSplitConfig(): Promise<void> {
  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  const [manualGroupCountInput] = process.argv.slice(2);

  const groupCount: number | undefined =
    manualGroupCountInput !== undefined
      ? parseInt(manualGroupCountInput, 10)
      : undefined;

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

  console.log({ slowFiles: slowFiles[0] });

  const splitConfig: FileGroup[] = splitFilesIntoGroups(slowFiles, groupCount);

  try {
    await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createCucumberSplitConfig();
