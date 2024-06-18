Feature: Cost Savings

  Consumer will be able to access Cost Savings page only when
  Financial Assistance feature is enabled. When FAA feature disabled,
  consumer shall not be able see or access Cost Savings page.


  Background:
    Given bs4_consumer_flow feature is disable
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

  Scenario: FAA Feature Is Enabled - Consumer can access the Cost Savings Page
    Given the FAA feature configuration is enabled
    Given the iap year selection feature is enabled
    And a family with financial application in <application_state> state exists
    And the user with consumer role is logged in
    And the user is RIDP verified
    When consumer visits home page
    And the Cost Savings link is visible
    And the consumer clicks on Cost Savings link
    Then the application year will be present on the table

  Scenario: FAA Feature Is Enabled - Consumer will see message if oe_application_warning_display feature is enabled
    Given the oe application warning display feature is enabled
    Given current hbx is not under open enrollment
    Given it is before open enrollment
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then the oe application warning will display

  Scenario: FAA Feature Is Enabled AND Filter index enabled - Consumer will see message if oe_application_warning_display feature is enabled
    Given the oe application warning display feature is enabled
    Given the filtered_application_list feature is enabled
    Given current hbx is not under open enrollment
    Given it is before open enrollment
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then the oe application warning will display

  Scenario: Consumer will not see message if after open enrollment
    Given the oe application warning display feature is enabled
    Given current hbx is not under open enrollment
    Given it is after open enrollment
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then the oe application warning will not display

  Scenario: FAA Feature Is Enabled - Consumer has nil fields for Incarcerated status
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    When Incarcerated field is nil for the consumer
    When consumer click 'Start New Application' button
    Then the consumer should see a message with incarcerated error

  Scenario: FAA Feature Is Enabled - Consumer has nil value for DOB
    Given the FAA feature configuration is enabled
    Given consumer visits home page
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    When DOB is nil for the consumer
    When consumer click 'Start New Application' button
    Then the consumer should see a message with dob error

  Scenario: Under Open Enrollment - Consumer should see OE Application warning message
    Given the oe application warning display feature is enabled
    Given current hbx is under open enrollment
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then the coverage update reminder warning will display

  Scenario: Not under Open Enrollment - Consumer should not see OE Application warning message
    Given the oe application warning display feature is enabled
    Given current hbx is not under open enrollment
    Given consumer visits home page
    And the Cost Savings link is visible
    When the consumer clicks the Cost Savings link
    Then the consumer will navigate to the Cost Savings page
    Then the coverage update reminder warning will not display
