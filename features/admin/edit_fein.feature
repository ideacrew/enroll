Feature: Update FEIN
  In order to update FEIN
  User should have the role of an Super Admin

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And there is an employer Xfinity Enterprise

    Scenario: HBX Staff with Super Admin enters FEIN without 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      When the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer
      And an FEIN with less than nine digits is entered
      And the user clicks submit button
      Then an warning message will be presented as FEIN must be at least nine digits

    Scenario: HBX Staff with Super Admin enters FEIN with 9 digits matching an existing employer
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      When the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer
      And an FEIN with nine digits matches an existing Employer Profile FEIN
      And the user clicks submit button
      Then an warning message will be presented as FEIN matches HBX ID Legal Name

    Scenario: HBX Staff with Super Admin enters a unique FEIN with 9 digits
      Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
      And the user is on the Employer Index of the Admin Dashboard
      When the user clicks Change FEIN link in the Actions dropdown for ABC Widgets Employer
      And the user enters unique FEIN with nine digits
      And the user clicks submit button
      Then a success message will display at the top of the index
