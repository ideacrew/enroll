Feature: Start a new Financial Assistance Application and fills out Income Adjustments form

  Background: User logs in and visits applicant's income adjustments page
    Given EnrollRegistry crm_update_family_save feature is disabled
    Given EnrollRegistry crm_publish_primary_subscriber feature is disabled
    Given FAA job_income_warning_message feature is disabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    When the user will navigate to the FAA Household Info page
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the income adjustments page via the left nav

  Scenario: User answers no to having income adjustments
    Given the user answers no to having income adjustments
    Then the income adjustments choices should not show

  Scenario: User answers yes to having other income
    Given the user answers yes to having income adjustments
    Then the income adjustments choices should show

  Scenario: Income adjustments form shows after checking an option
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    Then the income adjustments form should show

  Scenario: User enters other income adjustments
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    And the user fills out the required income adjustments information
    Then the save button should be enabled
    And the user saves the income adjustments information
    Then the income adjustment should be saved on the page

  Scenario: Existing adjustments are deleted when user selects "No" to income adjustments driver question
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    And the user fills out the required income adjustments information
    Then the save button should be enabled
    And the user saves the income adjustments information
    Then the income adjustment should be saved on the page
    And the user answers no to having income adjustments
    And the user answers clicks continue and remove
    And the user answers yes to having income adjustments
    Then the income adjustment form should not show

  Scenario: Cancel button functionality
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    When the user cancels the form
    Then the income adjustments checkbox should be unchecked
    And the income adjustment form should not show
