Feature: Cost Savings -  Start New Application

  Admin/Consumer/Broker will be able to access Cost Savings - Start New Application
  will be always enabled. If user clicks on Start New application button and if person has no
  existing applications then user will land on Application checklist page or else a modal pop
  up will show up

  Scenario Outline: FAA is enabled - and consumer has a FAA applications
    Given EnrollRegistry crm_update_family_save feature is disabled
    And EnrollRegistry crm_publish_primary_subscriber feature is disabled
    And the FAA feature configuration is enabled
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

  Scenario: FAA is enabled - year selection enabled - and consumer has a no existing FAA applications
    Given the iap year selection feature is enabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And the FAA feature configuration is enabled
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then consumer should see 'Start New Application' button
    When consumer click 'Start New Application' button
    Then the user will navigate to the assistance year selection page

  Scenario: FAA is enabled - year selection disabled - and consumer has a no existing FAA applications
    Given the iap year selection feature is disabled
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp
    And the FAA feature configuration is enabled
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then consumer should see 'Start New Application' button
    When consumer click 'Start New Application' button
    Then the consumer is navigated to Application checklist page
