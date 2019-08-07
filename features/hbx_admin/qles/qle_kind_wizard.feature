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
    Given the user is on the Main Page
    And the user goes to the Config Page
    And the user clicks the Manage QLE link
    And the user selects Create a Custom QLE and clicks submit
    When the user fills out the new QLE Kind form for Got a New Dog event and clicks submit
    # Then user should see a message that a new QLE Kind has been created Got a New Dog Qle Kind

  Scenario: HBX Staff with Super Admin subroles can edit a custom QLE Kind
    Given qualifying life event kind Got a New Dog present
    And the user visits the edit Qualifying Life Event Kind page for Got a New Dog QLE Kind
    # And the user is on the Main Page
    # And the user goes to the Config Page
    # When the user clicks the Manage QLE link
    # And the user selects Modify Existing QLE, Market Kind, and first QLE Kind and clicks submit
    # TODO: Need to figure out why the market_kind isn't showing. Produces the followign error:
    # Unable to find radio button "qle_wizard_kind_selected_radio_category_shop" that is not disabled 
    When the user fills out the edit QLE Kind form for Got a New Dog event and clicks submit
    # Then user should see a message that a QLE Kind has been created Got a New Dog QLE kind

  Scenario: HBX Staff with Super Admin subroles can deactivate a custom QLE Kind
    Given qualifying life event kind Had a New Dog present
    And the user visits the deactivate Qualifying Life Event Kind page for Got a New Dog QLE Kind
    # TODO: Should test the wizard redirecting here.
    # See above comment about selecting market kind
    When the user fills out the deactivate QLE Kind form for Got a New Dog event and clicks submit
    Then user should see a message that a new QLE Kind has been created Got a New Dog event
