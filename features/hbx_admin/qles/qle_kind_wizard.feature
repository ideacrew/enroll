Feature: As an HBX Admin User I can access the QLE Wizard management wizard
  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given all permissions are present
    And that a user with a HBX staff role with HBX staff subrole exists and is logged in

  Scenario: HBX Staff with Super Admin subroles can access and manage the QLE Wizard page
    Given the user is on the Main Page
    And the user goes to the Config Page
    When the user clicks the Manage QLE link
    Then the user should see the QLE Kind Wizard

  Scenario: HBX Staff with Super Admin subroles can create a custom QLE Kind
    Given the user visits the new Qualifying Life Event Kind page
    And the user selects Create a Custom QLE and clicks submit
    When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    Then user should see a message that a new QLE Kind has been created Got a New Dog event

  Scenario: HBX Staff with Super Admin subroles can edit a custom QLE Kind
    Given qualifying life event kind Had a New Dog present
    And the user visits the edit Qualifying Life Event Kind page
    And the user selects Create a Custom QLE and clicks submit
    When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    Then user should see a message that a new QLE Kind has been created Got a New Dog event

  Scenario: HBX Staff with Super Admin subroles can deactivate a custom QLE Kind
    Given qualifying life event kind Had a New Dog present
    And the user visits the deactivate Qualifying Life Event Kind page
    And the user selects Create a Custom QLE and clicks submit
    When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    Then user should see a message that a new QLE Kind has been created Got a New Dog event
