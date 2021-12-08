const { promises: fs } = require('fs');

import { CucumberFeature } from 'cucumber-report-analyzer';
import {
  createSplitConfig,
  FileWithRuntime,
  SplitConfig,
  runtimeDetails,
} from 'split-config-generator';

import { cucumberReportToRuntime } from './util/cucumberReportToRuntime';

const REPORT_PATH = './ci/cucumber/local-cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

async function createCucumberSplit(): Promise<void> {
  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  const [manualGroupCountInput] = process.argv.slice(2);

  const groupCount: number | undefined =
    manualGroupCountInput !== undefined
      ? parseInt(manualGroupCountInput, 10)
      : undefined;

  const files: FileWithRuntime[] = cucumberReportToRuntime(report);
  const splitConfig: SplitConfig = createSplitConfig(files, groupCount);
  console.log(runtimeDetails(files));

  try {
    await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
  } catch (e) {
    console.error(e);
  }
}

createCucumberSplit();
