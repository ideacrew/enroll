Feature: Employee passive renewal should be canceled when Employee waived coverage

  After passive renewal is generated for a renewing employee from previous year plan selection
  if employee chooses to waive coverage, passive renewal should be canceled

  Scenario: Renewing employee waive coverage
    Given Renewing Employer for Soren White exists with active and renewing plan year