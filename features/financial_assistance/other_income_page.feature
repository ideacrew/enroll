Feature: Start a new Financial Assistance Application and fills out Other Income form

  Background: User logs in and visits applicant's other income page
    Given bs4_consumer_flow feature is disable
    Given divorce agreement year feature is enabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    Given ssi types feature is enabled
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the other income page via the left nav
    And the user will navigate to the Other Income page for the corresponding applicant

  Scenario: User answers no to having other income
    Given the user answers no to having other income
    Then the other income choices should not show
  
  Scenario: Divorce agreement copy displays
    Given the user answers yes to having other income
    Then the other income choices should show
    Then the divorce agreement copy should show

  Scenario: Other Income form shows after checking an option
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    Then the other income form should show

  Scenario: User enters other income adjustments
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user fills out the required other income information
    Then the save button should be enabled
    And the user saves the other income information
    Then the other income information should be saved on the page

  Scenario: User enters other income information with a start date in the future
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user enters a start date in the future
    Then the user should see the start date warning message

  Scenario: User enters other income information with an end date
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user enters an end date
    Then the user should see the end date warning message

  Scenario: User enters other income information with a start date in the future and an end date
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user enters a start date in the future
    And the user enters an end date
    Then the user should see the start date and end date warning messages

  Scenario: Cancel button functionality
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    When the user cancels the form
    Then the other income checkbox should be unchecked
    And the other income form should not show

  Scenario: User answers no to having unemployment income
    Given the unemployment income feature is enabled
    Given the user answers no to having unemployment income
    Then the unemployment income choices should not show

  Scenario: User answers yes to having unemployment income
    Given the unemployment income feature is enabled
    Given the user answers yes to having unemployment income
    Then the unemployment income choices should show

  Scenario: Unemployment Income form shows after checking an option
    Given the user answers yes to having unemployment income
    Then the unemployment income form should show

  Scenario: User enters unemployment income adjustments
    Given the user answers yes to having unemployment income
    And the user fills out the required other income information
    Then the save button should be enabled
    And the user saves the other income information
    Then the other income information should be saved on the page

  Scenario: User enters unemployment information with a start date in the future
    Given the user answers yes to having unemployment income
    And the user enters a start date in the future
    Then the user should see the start date warning message

  Scenario: User enters unemployment information with an end date
    Given the user answers yes to having unemployment income
    And the user enters an end date
    Then the user should see the end date warning message

  Scenario: User enters unemployment information with a start date in the future and an end date
    Given the user answers yes to having unemployment income
    And the user enters a start date in the future
    And the user enters an end date
    Then the user should see the start date and end date warning messages

  Scenario: Unemployment Cancel button functionality
    Given the user answers yes to having unemployment income
    When the user cancels the form
    And the other income form should not show
    And NO should be selected again for unemployment income

  Scenario: Unemployment Not Sure popup shows correct text
    When the user clicks the Not sure link next to the unemployment income question
    Then the user should see the popup for the unemployment income question

  Scenario: User enters other income adjustments with negative Income amount
    Given the user answers yes to having other income
    And the user checks a other income checkbox
    And the user fills out the other income information with negative income
    Then the save button should be enabled
    And the user saves the other income information
    Then the other income information should not be saved

  Scenario: User enters negative Income amount for valid income type
    Given the user answers yes to having other income
    And the user checks capital gains checkbox
    And the user fills out the other income information with negative income
    Then the save button should be enabled
    And the user saves the other income information
    Then the negative other income information should be saved on the page

  Scenario: User enters Social Security income type
    Given the user answers yes to having other income
    And the user checks social security checkbox
    Then the social security benefit type choices should show
    Then the save button should be disabled
    Then the user selects a social security benefit type
    Then the user fills out the required other income information
    Then the save button should be enabled
