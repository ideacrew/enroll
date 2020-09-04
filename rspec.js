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
    .sort((a, b) => (a.runTime < b.runTime ? -1 : 1));

  const totalRuntime = arrayOfSlowFiles.reduce(
    (runtime, file) => runtime + file.runTime,
    0
  );

  const targetRuntimePerGroup = Math.floor(totalRuntime / numberOfGroups);

  const splitConfig = splitFilesIntoGroups(
    numberOfGroups,
    arrayOfSlowFiles,
    targetRuntimePerGroup
  );

  const jsonList = JSON.stringify(splitConfig);

  await fs.writeFile(`./${outputPath}/rspec-split-config.json`, jsonList);
}

getJson();

function splitFilesIntoGroups(numberOfGroups, arr, targetRuntimePerGroup) {
  console.log(
    "Splitting",
    arr.length,
    "files into",
    numberOfGroups,
    "groups, each being around",
    targetRuntimePerGroup,
    "seconds long."
  );
  let split = [];

  let bucketTimes = Array.from({ length: numberOfGroups }, () => ({
    runTime: 0,
  }));

  const length = arr.length;

  let bucket = 0;

  for (let file of arr) {
    console.log("Starting with bucket", bucket, bucketTimes[bucket]);
    const currentBucketTime = bucketTimes[bucket].runTime;

    if (currentBucketTime + file.runTime < targetRuntimePerGroup) {
      split[bucket] =
        split[bucket] === undefined
          ? { files: [file.filePath] }
          : { files: [...split[bucket].files, file.filePath] };

      bucketTimes[bucket].runTime += file.runTime;
    } else {
      console.log(file.filePath, "is to large to go into bucket", bucket);
      bucket += 1;
      split[bucket] =
        split[bucket] === undefined
          ? { files: [file.filePath] }
          : { files: [...split[bucket].files, file.filePath] };
      bucketTimes[bucket].runTime += file.runTime;
    }
  }

  console.log(bucketTimes);

  return split;
}

function removeLeadingDotSlash(filePath) {
  return filePath.replace(/\.\//, "");
}
