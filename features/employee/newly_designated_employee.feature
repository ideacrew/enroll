Feature: Newly designated employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under previous year plan year

Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer Acme Inc.
    And employer Acme Inc. has active and renewing enrollment_open benefit applications
    And Acme Inc. employer has a staff role 
    And there is a census employee record for Patrick Doe for employer Acme Inc.

  Scenario: Newly designated should not get effective date before renewing plan year start date
   Given Employer exists and logs in and adds and employee
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
