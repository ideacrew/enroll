Feature: Update FEIN
  In order to update FEIN
  User should have the role of an Super Admin

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a enrollment_open benefit application
    And this benefit application has a benefit package containing health benefits

    Scenario: HBX Staff with Super Admin clicks Change FEIN
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see the Change FEIN button
      When the user clicks the Change FEIN button
      Then the Change FEIN window will expand
      And the user will see the Change FEIN window
      And the user will see the editable New FEIN field
      And the user will see the Cancel - X
      And the user will see the Submit button

    Scenario: HBX Staff with Super Admin does not want to edit the FEIN
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see the Change FEIN button
      And the user will see the Change FEIN window
      And the user will see the Cancel - X
      When the user clicks the Cancel - X button
      Then the Change FEIN window will collapse

    Scenario: HBX Staff with Super Admin enters FEIN without 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see the Change FEIN button
      And the user will see the Change FEIN window
      And an FEIN with less than 9 digits is entered
      When the user clicks Submit button
      Then an warning message will be presented - FEIN must be at least 9 digits

    Scenario: HBX Staff with Super Admin enters FEIN with 9 digits matching an existing employer
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see the Change FEIN button
      And the user will see the Change FEIN window
      And an FEIN with 9 digits matches an existing Employer Profile FEIN
      When the user clicks Submit button
      Then an warning message will be presented - FEIN matches HBX ID ** Legal Name ***

    Scenario: HBX Staff with Super Admin enters a unique FEIN with 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see the Change FEIN button
      And the user will see the Change FEIN window
      And an FEIN with 9 digits matches an existing Employer Profile FEIN
      When the user clicks Submit button
      Then a success message will display at the top of the index
      And the Change FEIN window will collapse
