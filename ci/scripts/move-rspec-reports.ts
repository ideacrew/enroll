import { promises as fs } from 'fs';

const moveRspecReports = async () => {
  const compressedReportsFolders: string[] = await fs.readdir(
    './ci/rspec/compressed-reports'
  );

  for (let i = 0; i < compressedReportsFolders.length; i++) {
    const compressedReportFolder = compressedReportsFolders[i];
    const originalReportPath = `./ci/rspec/compressed-reports/${compressedReportFolder}/${compressedReportFolder}-rspec-report.json`;

    await fs.copyFile(
      originalReportPath,
      `./ci/rspec/${compressedReportFolder}-rspec-report.json`
    );
  }

  console.log(compressedReportsFolders);
};

moveRspecReports();
