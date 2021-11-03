Feature: Update DOB and SSN
  In order to update DOB and SSN
  User should have the role of an admin

  Background: Setup site, employer, benefit application and active employee
   Given all permissions are present
    Given individual Qualifying life events are present
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer ABC Widgets
    And initial employer ABC Widgets has enrollment_open benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And Patrick Doe has a consumer role and IVL enrollment

  @flaky
  Scenario: Admin enters invalid DOB or SSN
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And Admin clicks Families tab
    When the user clicks Action for a person on families index page
    Then the user will see the Edit DOB SSN button
    When user clicks on edit DOB/SSN link
    When user enters an invalid SSN and clicks on update
    Then Hbx Admin should see the edit form being rendered again with a validation error message

  Scenario: Admin enters valid DOB or SSN
    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And EnrollRegistry location_residency_verification_type feature is enabled
    And Admin clicks Families tab
    When the user clicks Action for a person on families index page
    Then the user will see the Edit DOB SSN button
    When user clicks on edit DOB/SSN link
    When Hbx Admin enters a valid DOB and SSN and clicks on update
    Then Hbx Admin should see the update partial rendered with update sucessful message
