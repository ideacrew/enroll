import { CucumberFeature } from './models';
import { promises as fs } from 'fs';

async function getJson() {
  console.log('Reading gha reports');

  const ghaDir: string[] = await fs.readdir('./ci/cucumber/gha-reports');

  console.log(ghaDir);

  const cucumberReports: CucumberFeature[][] = [];

  for (let index = 0; index < ghaDir.length; index++) {
    const feature = ghaDir[index];
    const file = await fs.readFile(
      `./ci/cucumber/gha-reports/${feature}/${feature}-cucumber-report.json`,
      'utf-8'
    );

    const report = JSON.parse(file);
    cucumberReports.push(report);
  }

  console.log('Converting reports to JSON');
  const jsonReport = JSON.stringify(cucumberReports.flat());

  await fs.writeFile('./ci/cucumber/gha-cucumber-report.json', jsonReport);
}

getJson();
