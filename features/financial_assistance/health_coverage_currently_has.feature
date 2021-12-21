Feature: Start a new Financial Assistance Application and answers questions on health coverage page

  Background: User logs in and visits applicant's health coverage page
    Given the shop market configuration is enabled
    Given a consumer, with a family, exists
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And FAA display_medicaid_question feature is enabled
    When they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page (health coverage)
    And they visit the Health Coverage page via the left nav (also confirm they are on the Health Coverage page)
  
  Scenario: User answers yes to currently having health coverage
    Given the user answers yes to currently having health coverage
    Then the health coverage choices should show

  Scenario: Health coverage form shows after checking an option (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    Then the health coverage form should show
  
  Scenario: User enters health coverage information (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    And the user fills out the required health coverage information
    Then the save button should be enabled
    And the user saves the health coverage information
    Then the health coverage should be saved on the page
  
  Scenario: Cancel button functionality (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a health coverage checkbox
    When the user cancels the form
    Then the health coverage checkbox should be unchecked
    And the health coverage form should not show

  Scenario: User enters hra information (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks a hra checkbox
    And the user fills out the required hra form
    Then the save button should be enabled
    And the user saves the health coverage information
    Then the hra health coverage should be saved on the page

  Scenario: User enters hra information (currently have coverage)
    Given the user answers yes to currently having health coverage
    And the user checks on not sure link for hra checkbox
    Then should see not sure modal pop up