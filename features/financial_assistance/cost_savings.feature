Feature: Cost Savings

  Consumer will be able to access Cost Savings page only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.


  Background:
    Given a consumer exists
    And the consumer is logged in
    And consumer has successful ridp

  Scenario: FAA Feature Is Disabled - Consumer can not see the Cost Savings Link
    Given the FAA feature configuration is disabled
    When consumer visits home page
    Then the consumer will not see the Cost Savings link

  Scenario: FAA Feature Is Disabled - Consumer can not have access to the Cost Savings Page
    Given the FAA feature configuration is disabled
    When the consumer manually enters the "Cost Savings" url in the browser search bar
    Then the consumer will not have access to the Cost Savings page

  Scenario: FAA Feature Is Enabled - Consumer can see the Cost Savings Link
    Given the FAA feature configuration is enabled
    When consumer visits home page
    Then the Cost Savings link is visible

  Scenario: FAA Feature Is Enabled - Consumer can navigate to the Cost Savings Page
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page

  Scenario: FAA Feature Is Enabled - Consumer can access the Cost Savings Page
    Given the FAA feature configuration is enabled
    When the consumer manually enters the "Cost Savings" url in the browser search bar
    Then the consumer will navigate to the Cost Savings page

  Scenario: FAA Feature Is Enabled - Consumer has nil fields for Incarcerated status
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    When Incarcerated field is nil for the consumer
    Then they click 'Start New Application' button
    Then the consumer should see a message with incarcerated error

  Scenario: FAA Feature Is Enabled - Consumer has nil value for DOB
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    When DOB is nil for the consumer
    Then they click 'Start New Application' button
    Then the consumer should see a message with dob error

  Scenario: FAA Feature Is Enabled - Consumer has a terminated application
    Given the FAA feature configuration is enabled
    When that a family has a Financial Assistance application in the terminated state
    Then consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then Start New Application button should be enabled

  Scenario: FAA Feature Is Enabled - Consumer has a cancelled application
    Given the FAA feature configuration is enabled
    When that a family has a Financial Assistance application in the cancelled state
    Then consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then Start New Application button should be enabled
