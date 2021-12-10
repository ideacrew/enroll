import { promises as fs } from 'fs';
import { RspecExample, RspecReport } from './models';

async function getJson(): Promise<void> {
  console.log('Reading gha reports');
  const ghaDir: string[] = await fs.readdir('./ci/rspec');

  const ghaReports = ghaDir.filter((file) => file.endsWith('.json'));

  const rspecReports: RspecReport[] = [];

  for (let index = 0; index < ghaReports.length; index++) {
    const path = ghaReports[index];
    const file = await fs.readFile(`./ci/rspec/${path}`, 'utf-8');

    const report = JSON.parse(file);
    rspecReports.push(report);
  }

  const examples: RspecExample[] = rspecReports
    .map((report) => report.examples)
    .flat()
    .filter((report) => report.status !== 'pending');

  await fs.writeFile(
    './ci/rspec/local-rspec-report.json',
    JSON.stringify(examples)
  );
}

getJson();
