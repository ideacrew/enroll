Feature: Create Benefit Application by admin UI

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role

  Scenario: Existing Draft Application
    Given initial employer ABC Widgets has draft benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a success message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the draft application will be created
    And the existing applications for ABC Widgets will be Canceled

  Scenario Outline: Existing <title> Application for cancel button
    Given initial employer ABC Widgets has <before_submit> benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a pop up modal with "Confirm" or "Cancel" action
    When the admin clicks Cancel
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    Then the existing applications for ABC Widgets will be <title>
    And the new plan year will NOT be created.

    Examples:
      | title                 | before_submit         | after_submit        |
      | Publish Pending       | pending               | Canceled            |
      | Enrolling             | enrollment_open       | Canceled            |
      | Enrollment Closed     | enrollment_closed     | Canceled            |
      | Enrolled              | binder_paid           | Canceled            |
      | Enrollment Ineligible | enrollment_ineligible | Canceled            |
      | Active                | active                | Termination Pending |

  Scenario Outline: Existing <title> Application for confirm  button
    Given initial employer ABC Widgets has <before_submit> benefit application
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer
    And the user has clicked the Create Plan Year button
    And the user has a valid input for all required fields
    When the admin clicks SUBMIT
    Then the user will see a pop up modal with "Confirm" or "Cancel" action
    When the admin clicks CONFIRM
    Then the user will see a success message
    And staff role person logged in
    And ABC Widgets goes to the benefits tab I should see plan year information
    And the draft application will be created
    And the existing applications for ABC Widgets will be <after_submit>

    Examples:
      | title                 | before_submit         | after_submit        |
      | Publish Pending       | pending               | Canceled            |
      | Enrolling             | enrollment_open       | Canceled            |
      | Enrollment Closed     | enrollment_closed     | Canceled            |
      | Enrolled              | binder_paid           | Canceled            |
      | Enrollment Ineligible | enrollment_ineligible | Canceled            |
      | Active                | active                | Termination Pending |