const { promises: fs } = require('fs');

import { FeatureStep, FileWithRuntime, SplitConfig } from './models';
import { CucumberFeature } from './models';
import { splitFilesIntoGroups } from './util';

const REPORT_PATH = './ci/cucumber/cucumber-report.json';
const SPLIT_CONFIG_PATH = './ci/cucumber-split-config.json';

function calculateStepsRuntime(steps: FeatureStep[]) {
  return steps.reduce((runTime, step) => {
    if (typeof step.result.duration !== 'number') {
      console.log(step.result);
    }
    return runTime + step.result.duration;
  }, 0);
}

async function createCucumberSplitConfig() {
  // Read in cli arguments
  const [numberOfGroups] = process.argv.slice(2);

  if (numberOfGroups === undefined) {
    throw new Error('Please provide the required cli arguments.');
  }

  // Parse cucumber report
  const cucumberReport = await fs.readFile(REPORT_PATH, 'utf-8');
  const report: CucumberFeature[] = JSON.parse(cucumberReport);

  // Generate list of slow files
  const arrayOfSlowFiles: FileWithRuntime[] = report
    .map((feature: CucumberFeature) => {
      const totalRunTime = feature.elements.reduce((totalTime, element) => {
        const stepRunTime = calculateStepsRuntime(element.steps);

        return totalTime + stepRunTime;
      }, 0);

      const runtimeInfo: FileWithRuntime = {
        filePath: feature.uri,
        runTime: totalRunTime / 1_000_000,
      };
      return runtimeInfo;
    })
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  const splitConfig: SplitConfig[] = splitFilesIntoGroups(
    +numberOfGroups,
    arrayOfSlowFiles
  );

  await fs.writeFile(SPLIT_CONFIG_PATH, JSON.stringify(splitConfig));
}

// function splitFilesIntoGroups(
//   numberOfGroups: number,
//   arr: FileWithRuntime[]
// ): SplitConfig[] {
//   let split: SplitConfig[] = [];

//   const length = arr.length;
//   for (let i = 0; i < length; i++) {
//     // e.g. 0 % 20 = 0, 1 % 20 = 1, 43 % 20 = 3
//     const bucket = i % numberOfGroups;

//     split[bucket] =
//       split[bucket] === undefined
//         ? { files: [arr[i].filePath] }
//         : { files: [...split[bucket].files, arr[i].filePath] };
//   }

//   return split;
// }

createCucumberSplitConfig();
