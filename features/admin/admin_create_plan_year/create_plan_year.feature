Feature: Super Admin & tier3 able to see & access "Create Plan Year" Feature.

  Background: HBX Staff with <subrole> subroles should <action> Create Plan Year button
    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has draft plan year
    When Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And the Hbx Admin clicks on the Action button
    
  Scenario: HBX Staff with Super Admin sub roles should see Create Plan Year button
    Then Hbx Admin should see an Create Plan Year button

  Scenario: HBX Staff with Super Admin sub roles should see the Create Plan Year Form
    When the Hbx Admin clicks on Create Plan Year link
    Then the Hbx Admin will see the Create Plan Year option row

  Scenario: Submit button will be disabled until all required fields have been filled.
    When the Hbx Admin clicks on Create Plan Year link
    Then the Create Plan Year form submit button will be disabled

  Scenario: Cancel the Create Plan Year new plan year
    When the Hbx Admin clicks on Create Plan Year link
    Then the Hbx Admin will see the Create Plan Year option row
    When the Hbx Admin clicks the X icon on the Create Plan Year form
    Then the Create Plan Year option row will no longer be visible

  Scenario: Open Enrollment Start Date and Open Enrollment End Date will be disabled until user selects a Start Date
    When the Hbx Admin clicks on Create Plan Year link
    Then the Effective End Date for the Create Plan Year form will be blank
    Then the Open Enrollment Start Date for the Create Plan Year form will be disabled
    Then the Open Enrollment End Date for the Create Plan Year form will be disabled

  Scenario: Open Enrollment Start Date and Open Enrollment End Date will be disabled until user selects a Start Date
    When the Hbx Admin clicks on Create Plan Year link
    Then the Hbx Admin selects an Effective Start Date from the Create Plan Year form
    Then the Effective End Date for the Create Plan Year form will be filled in
    Then the Open Enrollment Start Date for the Create Plan Year form will be enabled
    Then the Open Enrollment End Date for the Create Plan Year form will be enabled
