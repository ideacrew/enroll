const { promises: fs } = require("fs");

async function getJson() {
  const response = await fs.readFile("./ci/small-report.json", "utf-8");

  const { version, examples, summary, summary_line } = JSON.parse(response);

  const splitConfig = examples.reduce((totalConfig, example) => {
    const filePath = example.file_path;

    if (totalConfig[filePath] !== undefined) {
      const currentTotal = totalConfig[filePath].runTime;

      return {
        ...totalConfig,
        [filePath]: { currentTotal: currentTotal + example.run_time },
      };
    } else {
      return {
        ...totalConfig,
        [filePath]: { currentTotal: example.run_time },
      };
    }
  }, {});

  console.log(splitConfig);
}

getJson();
