Feature: test

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

  Scenario: Existing Publish Pending Application
    Given initial employer ABC Widgets has pending benefit application
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
    Then the existing applications for ABC Widgets will be Publish Pending
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has pending benefit application
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
    And the existing applications for ABC Widgets will be Canceled

  Scenario: Existing Enrolling Application
    Given initial employer ABC Widgets has enrollment_open benefit application
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
    Then the existing applications for ABC Widgets will be Enrolling
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has enrollment_open benefit application
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
    And the existing applications for ABC Widgets will be Canceled

  Scenario: Existing Enrollment Closed Application
    Given initial employer ABC Widgets has enrollment_closed benefit application
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
    Then the existing applications for ABC Widgets will be Enrollment Closed
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has enrollment_closed benefit application
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
    And the existing applications for ABC Widgets will be Canceled

  Scenario: Existing Enrolled Application
    Given initial employer ABC Widgets has binder_paid benefit application
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
    Then the existing applications for ABC Widgets will be Enrolled
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has binder_paid benefit application
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
    And the existing applications for ABC Widgets will be Canceled

  Scenario: Existing Enrollment Ineligible Application
    Given initial employer ABC Widgets has enrollment_ineligible benefit application
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
    Then the existing applications for ABC Widgets will be Enrollment Ineligible
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has enrollment_ineligible benefit application
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
    And the existing applications for ABC Widgets will be Canceled

  Scenario: Existing Active Application
    Given initial employer ABC Widgets has active benefit application
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
    Then the existing applications for ABC Widgets will be Active
    And the new plan year will NOT be created.

    Given initial employer ABC Widgets has active benefit application
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
    And the existing applications for ABC Widgets will be Termination Pending
