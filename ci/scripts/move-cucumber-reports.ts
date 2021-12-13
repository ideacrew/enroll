import { promises as fs } from 'fs';

const moveCucumberReports = async () => {
  const compressedReportsFolders: string[] = await fs.readdir(
    './ci/cucumber/compressed-reports'
  );

  for (let i = 0; i < compressedReportsFolders.length; i++) {
    // Get the folder name, e.g. admin, cover_all, etc.
    const compressedReportFolder = compressedReportsFolders[i];

    // Create the full json report path
    const originalReportPath = `./ci/cucumber/compressed-reports/${compressedReportFolder}/${compressedReportFolder}-cucumber-report.json`;

    await fs.copyFile(
      originalReportPath,
      `./ci/cucumber/${compressedReportFolder}-cucumber-report.json`
    );
  }

  console.log(compressedReportsFolders);
};

moveCucumberReports();
