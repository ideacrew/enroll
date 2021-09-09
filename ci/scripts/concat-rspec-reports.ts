import { promises as fs } from 'fs';
import { FileWithRuntimeDictionary, RspecExample, RspecReport } from './models';
import { createFileDictionary } from './util';

async function getJson(): Promise<RspecReport[]> {
  console.log('Reading gha reports');
  const ghaDir: string[] = await fs.readdir('./ci/rspec/gha');

  const rspecReports: RspecReport[] = [];

  for (let index = 0; index < ghaDir.length; index++) {
    const path = ghaDir[index];
    const file = await fs.readFile(`./ci/rspec/gha/${path}`, 'utf-8');

    const report = JSON.parse(file);
    rspecReports.push(report);
  }

  return rspecReports;
}

export const runtimeDictionary =
  async (): Promise<FileWithRuntimeDictionary> => {
    console.log('Creating runtime dictionary');
    const reports = await getJson();

    const examplesOnly: RspecExample[] = reports
      .map((report) => report.examples)
      .flat()
      .filter((report) => report.status !== 'pending');

    return createFileDictionary(examplesOnly);
  };
