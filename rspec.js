const { promises: fs } = require("fs");

async function getJson() {
  const response = await fs.readFile("./ci/rspec-report.json", "utf-8");

  const { version, examples, summary, summary_line } = JSON.parse(response);

  const filesByRuntime = examples.reduce((totalConfig, example) => {
    const filePath = example.file_path;

    if (totalConfig[filePath] !== undefined) {
      const currentTotal = totalConfig[filePath].runTime;

      return {
        ...totalConfig,
        [filePath]: { runTime: currentTotal + example.run_time },
      };
    } else {
      return {
        ...totalConfig,
        [filePath]: { runTime: example.run_time },
      };
    }
  }, {});

  // 20 slowest files
  const arrayOfSlowFiles = Object.entries(filesByRuntime)
    .map(([key, value]) => ({
      filePath: removeLeadingDotSlash(key),
      ...value,
    }))
    .sort((a, b) => (a.runTime < b.runTime ? 1 : -1));

  const splitConfig = splitFilesIntoGroups(20, arrayOfSlowFiles);

  const jsonList = JSON.stringify(splitConfig);

  await fs.writeFile("./ci/split-config.json", jsonList);
}

getJson();

function splitFilesIntoGroups(numberOfGroups, arr) {
  console.log("Splitting", arr.length, "files into", numberOfGroups, "groups");
  let split = [];

  for (let i = 0; i < arr.length; i++) {
    const bucket = i % numberOfGroups;

    console.log("Putting files into bucket", bucket);

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
