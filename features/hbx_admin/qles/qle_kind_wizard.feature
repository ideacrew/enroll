Feature: As an HBX Admin User I can access the QLE Wizard management wizard
  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given all permissions are present

  Scenario: HBX Staff with Super Admin subroles can access and manage the QLE Wizard page
    Given all permissions are present
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Main Page
    And the user goes to the Config Page
    And the user clicks the Manage QLE link
    Then the user should see the QLE Kind Wizard

  Scenario: HBX Staff with Super Admin subroles can create a new custom QLE Kind
    Given all permissions are present
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in
    When the user visits the new Qualifying Life Event Kind page
    And the user fills out the new QLE Kind form for Got a New Dog event
    And the user clicks submit
    Then user should see a message that a new QLE Kind has been created Got a New Dog event