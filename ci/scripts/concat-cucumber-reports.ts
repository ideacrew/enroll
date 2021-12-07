import { CucumberFeature } from 'cucumber-report-analyzer';

const { promises: fs } = require('fs');

async function getJson() {
  const allFiles: string[] = await fs.readdir('./ci/cucumber');

  const cucumberReports = allFiles.filter((file) => file.endsWith('.json'));

  let singleReport: CucumberFeature[] = [];

  for (let index = 0; index < cucumberReports.length; index++) {
    const path = `./ci/cucumber/${cucumberReports[index]}`;

    const report: string = await fs.readFile(path, 'utf8');

    singleReport.push(JSON.parse(report));
  }

  const jsonList: string = JSON.stringify(singleReport.flat());

  await fs.writeFile('./ci/cucumber/local-cucumber-report.json', jsonList);
}

getJson();
