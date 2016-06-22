Feature: Employee passive renewal should be canceled when Employee select coverage

  After passive renewal is generated for a renewing employee from previous year plan selection
  if employee makes a plan selection, passive renewal should be canceled

  Scenario: Renewing employee makes plan selection
    Given Renewing Employer for Soren White exists with active and renewing plan year