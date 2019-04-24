Feature: Update DOB and SSN
    In order to update DOB and SSN
    User should have the role of an admin

  Background: Setup site, employer, benefit application and active employee
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And Qualifying life events are present
    And there is an employer ACME Widgets, Inc.
    And employer ACME Widgets, Inc. has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer ACME Widgets, Inc.
    And ACME Widgets, Inc. employer has a staff role
    And staff role person logged in
    And ACME Widgets, Inc. employer visit the Employee Roster
    And Employer logs out
    And Employee has not signed up as an HBX user
    And Patrick Doe visits the employee portal
    And Patrick Doe creates an HBX account
    And I select the all security question and give the answer
    And I have submitted the security questions
    And Employee goes to register as an employee
    And Employee enters the identifying info of Patrick Doe
    And Employee should see the matched employee record form
    And Employee accepts the matched employer
    And Employee completes the matched employee form for Patrick Doe
    And Employee sees the Household Info: Family Members page and clicks Continue
    And Employee sees the Choose Coverage for your Household page and clicks Continue
    And Employee selects the first plan available
    And Employee clicks Confirm
    And Employee sees the Enrollment Submitted page and clicks Continue
    And Employee Patrick Doe should see their plan start date on the page
    And Hbx Admin logs out

 Scenario: Admin enters invalid DOB or SSN
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Family Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Edit DOB SSN button
    When user clicks on edit DOB/SSN link
    When user enters an invalid SSN and clicks on update
    Then Hbx Admin should see the edit form being rendered again with a validation error message
    And Hbx Admin logs out

 Scenario: Admin enters valid DOB or SSN
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Family Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Edit DOB SSN button
    When user clicks on edit DOB/SSN link
    When Hbx Admin enters a valid DOB and SSN and clicks on update
    Then Hbx Admin should see the update partial rendered with update sucessful message
    And Hbx Admin logs out