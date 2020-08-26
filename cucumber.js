const { promises: fs } = require("fs");

function calculateStepsRuntime(steps) {
  return steps.reduce((runTime, step) => {
    return runTime + step.result.duration;
  }, 0);
}

async function getJson() {
  const [numberOfGroups] = process.argv.slice(2);
  const response = await fs.readFile("./ci/cucumber-report.json", "utf-8");

  const report = JSON.parse(response);

  const arrayOfSlowFiles = report
    .map((feature) => {
      const totalRunTime = feature.elements.reduce((totalTime, element) => {
        const stepRunTime = calculateStepsRuntime(element.steps);

        return totalTime + stepRunTime;
      }, 0);

      return { filePath: feature.uri, runtime: totalRunTime / 1_000_000 };
    })
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  const splitConfig = splitFilesIntoGroups(numberOfGroups, arrayOfSlowFiles);

  const jsonList = JSON.stringify(splitConfig);

  await fs.writeFile("./ci/cucumber-split-config.json", jsonList);
}

function splitFilesIntoGroups(numberOfGroups, arr) {
  console.log("Splitting", arr.length, "files into", numberOfGroups, "groups");

  let split = [];

  const length = arr.length;
  for (let i = 0; i < length; i++) {
    // e.g. 0 % 20 = 0, 1 % 20 = 1, 43 % 20 = 3
    const bucket = i % numberOfGroups;

    split[bucket] =
      split[bucket] === undefined
        ? { files: [arr[i].filePath] }
        : { files: [...split[bucket].files, arr[i].filePath] };
  }

  return split;
}

getJson();

function splitFilesIntoGroups(numberOfGroups, arr) {
  console.log("Splitting", arr.length, "files into", numberOfGroups, "groups");
  let split = [];

  const length = arr.length;
  for (let i = 0; i < length; i++) {
    // e.g. 0 % 20 = 0, 1 % 20 = 1, 43 % 20 = 3
    const bucket = i % numberOfGroups;

    split[bucket] =
      split[bucket] === undefined
        ? { files: [arr[i].filePath] }
        : { files: [...split[bucket].files, arr[i].filePath] };
  }

  return split;
}

function removeLeadingDotSlash(filePath) {
  return filePath.replace(/\.\//, "");
}
