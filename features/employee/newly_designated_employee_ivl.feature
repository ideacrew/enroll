Feature: Newly designated employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under previous year plan year
  When IVL market is disabled.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Acme Inc.
    And Acme Inc. employer has a staff role

 Scenario: Newly designated should see the shop market place workflow as default
   Given Employer exists and logs in and adds and employee
    And employer Acme Inc. has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    And I select the all security question and give the answer
    When I have submitted the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    And Employee should see the shop market place workflow as default

Scenario: Newly designated should not see the individual market place workflow #We don't support IVL functionality
    Given Employer exists and logs in and adds and employee
    And employer Acme Inc. has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer Acme Inc.
    And Acme Inc. employer visit the Employee Roster
    Then Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    When Patrick Doe creates an HBX account
    And I select the all security question and give the answer
    When I have submitted the security questions
    When Employee goes to register as an employee
    Then Employee should see the employee search page
    When Employee enters the identifying info of Patrick Doe
    Then Employee should see the matched employee record form
    And Employee should not see the individual market place workflow