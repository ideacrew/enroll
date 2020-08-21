const { promises: fs } = require("fs");

function calculateStepsRuntime(steps) {
  return steps.reduce((runTime, step) => {
    return runTime + step.result.duration;
  }, 0);
}

async function getJson() {
  const admin = await fs.readFile("./ci/c-final/admin-report.json", "utf-8");
  const broker = await fs.readFile("./ci/c-final/broker-report.json", "utf-8");
  const coverall = await fs.readFile(
    "./ci/c-final/coverall-report.json",
    "utf-8"
  );
  const employee = await fs.readFile(
    "./ci/c-final/employee-report.json",
    "utf-8"
  );
  const employers = await fs.readFile(
    "./ci/c-final/employers-report.json",
    "utf-8"
  );
  const generalAgencies = await fs.readFile(
    "./ci/c-final/general-agencies-report.json",
    "utf-8"
  );
  const groupSelection = await fs.readFile(
    "./ci/c-final/group-selection-report.json",
    "utf-8"
  );
  const hbxAdmin = await fs.readFile(
    "./ci/c-final/hbx-admin-report.json",
    "utf-8"
  );
  const hbx = await fs.readFile("./ci/c-final/hbx-report.json", "utf-8");
  const insured = await fs.readFile(
    "./ci/c-final/insured-report.json",
    "utf-8"
  );
  const integration = await fs.readFile(
    "./ci/c-final/integration-report.json",
    "utf-8"
  );
  const permissions = await fs.readFile(
    "./ci/c-final/permissions-report.json",
    "utf-8"
  );
  const planShopping = await fs.readFile(
    "./ci/c-final/plan-shopping-report.json",
    "utf-8"
  );

  const jsonFiles = [
    admin,
    broker,
    coverall,
    employee,
    employers,
    generalAgencies,
    groupSelection,
    hbxAdmin,
    hbx,
    insured,
    integration,
    permissions,
    planShopping,
  ];

  const allReports = jsonFiles.reduce((allReports, report) => {
    const parsed = JSON.parse(report);
    // console.log(parsed);

    return [...allReports, ...parsed];
  }, []);

  const jsonList = JSON.stringify(allReports);

  await fs.writeFile("./ci/cucumber-report.json", jsonList);
}

getJson();
