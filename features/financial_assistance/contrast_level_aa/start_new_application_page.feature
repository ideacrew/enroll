Feature: Cost Savings -  Start New Application

  Admin/Consumer/Broker will be able to access Cost Savings - Start New Application
  will be always enabled. If user clicks on Start New application button and if person has no
  existing applications then user will land on Application checklist page or else a modal pop
  up will show up

  Scenario Outline: FAA is enabled - and consumer has a FAA applications
    Given the FAA feature configuration is enabled
    And a family with financial application in <application_state> state exists
    And the user with consumer role is logged in
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then consumer should see 'Start New Application' button

    Examples:
      | application_state |
      | draft  |
      | submitted |
      | determined |

  Scenario: FAA is enabled - year selection enabled - contrast level aa is enabled - and consumer has a no existing FAA applications
    Given the contrast level aa feature is enabled
    And the iap year selection feature is enabled
    And the iap year selection form feature is enabled
    And current hbx is under open enrollment
    Given the date is within open enrollment
    Given a consumer exists
    And the consumer is logged in
    And the date is within open enrollment
    And consumer has successful ridp
    And the FAA feature configuration is enabled
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then consumer should see 'Start New Application' button
    When consumer click 'Start New Application' button
    Then the user will navigate to the assistance year selection page with multiple options
    Then the page passes minimum level aa contrast guidelines
  
  Scenario: FAA is enabled - year selection enabled - OE ended - year selection form enabled - contrast level aa is enabled - and consumer has a no existing FAA applications
    Given the contrast level aa feature is enabled
    And the iap year selection feature is enabled
    And the iap year selection form feature is enabled
    And current hbx is not under open enrollment
    Given the date is after open enrollment
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And the FAA feature configuration is enabled
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then consumer should see 'Start New Application' button
    When consumer click 'Start New Application' button
    And the user will navigate to the non-OE assistance year selection page
    Then the page passes minimum level aa contrast guidelines