const { promises: fs } = require("fs");

// Usage
// node split rspec <path-to-report> <split-groups> <folder-to-save-config>

async function getJson() {
  const [filePath, numberOfGroups, outputPath] = process.argv.slice(2);
  const response = await fs.readFile(`./${filePath}`, "utf-8");

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

  const arrayOfSlowFiles = Object.entries(filesByRuntime)
    .map(([key, value]) => ({
      filePath: removeLeadingDotSlash(key),
      ...value,
    }))
    .sort((a, b) => (a.runTime < b.runTime ? 1 : -1));

  const splitConfig = splitFilesIntoGroups(numberOfGroups, arrayOfSlowFiles);

  const jsonList = JSON.stringify(splitConfig);

  await fs.writeFile(`./${outputPath}/rspec-split-config.json`, jsonList);
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
