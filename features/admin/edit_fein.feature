Feature: Update FEIN
  In order to update FEIN
  User should have the role of an Super Admin

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And there is an another employer Xfinity Enterprise
    And this employer has a enrollment_open benefit application
    And this benefit application has a benefit package containing health benefits

    Scenario: HBX Staff with Super Admin clicks Change FEIN
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see Change FEIN link
      When the user clicks Change FEIN
      Then the Change FEIN window will expand
      And the user will see editable New FEIN field
      And the user will see Cancel X button
      And the user will see submit button

    Scenario: HBX Staff with Super Admin does not want to edit the FEIN
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see Change FEIN link
      And the user clicks Change FEIN
      And the Change FEIN window will expand
      And the user will see Cancel X button
      When the user clicks Cancel X button
      Then the Change FEIN window will collapse

    Scenario: HBX Staff with Super Admin enters FEIN without 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see Change FEIN link
      And the user clicks Change FEIN
      And the Change FEIN window will expand
      And an FEIN with less than nine digits is entered
      When the user clicks submit button
      Then an warning message will be presented as FEIN must be at least nine digits

    Scenario: HBX Staff with Super Admin enters FEIN with 9 digits matching an existing employer
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see Change FEIN link
      And the user clicks Change FEIN
      And the Change FEIN window will expand
      And an FEIN with nine digits matches an existing Employer Profile FEIN
      When the user clicks submit button
      Then an warning message will be presented as FEIN matches HBX ID Legal Name

    Scenario: HBX Staff with Super Admin enters a unique FEIN with 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      And the user clicks Action for that Employer
      And the user will see Change FEIN link
      And the user clicks Change FEIN
      And the Change FEIN window will expand
      And the user enters unique FEIN with nine digits
      When the user clicks submit button
      Then a success message will display at the top of the index
      And the Change FEIN window will collapse
