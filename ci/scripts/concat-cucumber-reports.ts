const { promises: fs } = require('fs');

async function getJson() {
  const allFiles: string[] = await fs.readdir('./ci/cucumber');

  const cucumberReports = allFiles.filter((file) => file.endsWith('.json'));

  let singleReport = [];

  for (let index = 0; index < cucumberReports.length; index++) {
    const path = `./ci/cucumber/${cucumberReports[index]}`;

    const report = await fs.readFile(path, 'utf8');

    singleReport.push(JSON.parse(report));
  }

  const jsonList = JSON.stringify(singleReport.flat());

  await fs.writeFile('./ci/cucumber/local-cucumber-report.json', jsonList);
}

getJson();
