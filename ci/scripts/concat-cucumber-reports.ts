const { promises: fs } = require('fs');

async function getJson() {
  const admin = await fs.readFile(
    './ci/cucumber/admin-cucumber-report.json',
    'utf-8'
  );
  const broker = await fs.readFile(
    './ci/cucumber/brokers-cucumber-report.json',
    'utf-8'
  );
  const coverall = await fs.readFile(
    './ci/cucumber/cover_all-cucumber-report.json',
    'utf-8'
  );
  const employee = await fs.readFile(
    './ci/cucumber/employee-cucumber-report.json',
    'utf-8'
  );
  const employers = await fs.readFile(
    './ci/cucumber/employers-cucumber-report.json',
    'utf-8'
  );
  const financialAssistance = await fs.readFile(
    './ci/cucumber/financial_assistance-cucumber-report.json',
    'utf-8'
  );
  const generalAgencies = await fs.readFile(
    './ci/cucumber/general_agencies-cucumber-report.json',
    'utf-8'
  );
  const groupSelection = await fs.readFile(
    './ci/cucumber/group_selection-cucumber-report.json',
    'utf-8'
  );
  const hbx = await fs.readFile(
    './ci/cucumber/hbx-cucumber-report.json',
    'utf-8'
  );
  const hbxAdmin = await fs.readFile(
    './ci/cucumber/hbx_admin-cucumber-report.json',
    'utf-8'
  );
  const insured = await fs.readFile(
    './ci/cucumber/insured-cucumber-report.json',
    'utf-8'
  );

  const permissions = await fs.readFile(
    './ci/cucumber/permissions-cucumber-report.json',
    'utf-8'
  );
  const planShopping = await fs.readFile(
    './ci/cucumber/plan_shopping-cucumber-report.json',
    'utf-8'
  );

  const jsonFiles = [
    admin,
    broker,
    coverall,
    employee,
    employers,
    financialAssistance,
    generalAgencies,
    groupSelection,
    hbxAdmin,
    hbx,
    insured,
    permissions,
    planShopping,
  ];

  const allReports = jsonFiles.reduce((allReports, report) => {
    const parsed = JSON.parse(report);

    return [...allReports, ...parsed];
  }, []);

  const jsonList = JSON.stringify(allReports);

  await fs.writeFile('./ci/cucumber/local-cucumber-report.json', jsonList);
}

getJson();
