Feature: Insured Plan Shopping on Individual market Document Errors

  Background:
    Given bs4_consumer_flow feature is disable
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    Given AI AN Details feature is enabled
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information

  Scenario: Individual should see consumer fields when applying for coverage.
    When Individual selects applying for coverage
    Then the question "Is this person a US citizen or US national?" is displayed
    Then the question "Is this person a member of an American Indian Or Alaska Native Tribe?" is displayed
    Then the question "Is this person currently incarcerated?" is displayed
    Then the question "What is your race/ethnicity? (OPTIONAL - check all that apply)" is displayed

  Scenario: Individual should see consumer fields when applying for coverage.
    When Individual selects applying for coverage
    Then the question "Is this person a US citizen or US national?" is displayed
    Then the question "Is this person a member of an American Indian Or Alaska Native Tribe?" is displayed
    Then the question "Is this person currently incarcerated?" is displayed
    Then the question "What is your race/ethnicity? (OPTIONAL - check all that apply)" is displayed
    When AI AN question is answered yes
    Then the question "Where is this person's tribe located?" is displayed
    When tribal state dropdown box is clicked
    Then states dropdown should popup

  Scenario: Individual should not see consumer fields when not applying for coverage.
    When Individual selects not applying for coverage
    Then the question "Is this person a US citizen or US national?" is not displayed
    Then the question "Do you have eligible immigration status? " is not displayed
    Then the question "Is this person a member of an American Indian Or Alaska Native Tribe?" is displayed
    Then the question "Is this person currently incarcerated?" is not displayed
    Then the question "What is your race/ethnicity? (OPTIONAL - check all that apply)" is not displayed

  Scenario: Individual should not see consumer fields when not applying for coverage.
    When Individual selects not applying for coverage
    Then the question "Is this person a US citizen or US national?" is not displayed
    Then the question "Do you have eligible immigration status? " is not displayed
    Then the question "Is this person a member of an American Indian Or Alaska Native Tribe?" is displayed
    Then the question "Is this person currently incarcerated?" is not displayed
    Then the question "What is your race/ethnicity? (OPTIONAL - check all that apply)" is not displayed
    When AI AN question is answered yes
    Then the question "Where is this person's tribe located?" is displayed
    When tribal state dropdown box is clicked
    Then states dropdown should popup
