Feature: Start a new Financial Assistance Application and fills out Income Adjustments form

  Background: User logs in and visits applicant's income adjustments page
    Given bs4_consumer_flow feature is disable
    Given EnrollRegistry crm_update_family_save feature is disabled
    Given EnrollRegistry crm_publish_primary_subscriber feature is disabled
    Given divorce agreement year feature is disabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the consumer is RIDP verified
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
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
    Then the divorce agreement copy should not show

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

  Scenario: User enters other income information with a start date in the future
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    And the user enters a start date in the future for the deduction
    Then the user should see the start date warning message

  Scenario: User enters other income information with an end date
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    And the user enters an end date for the deduction
    Then the user should see the end date warning message

  Scenario: User enters other income information with a start date in the future and an end date
   Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    And the user enters a start date in the future for the deduction
    And the user enters an end date for the deduction
    Then the user should see the start date and end date warning messages

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

  Scenario: Divorce agreement copy displays
    Given divorce agreement year feature is enabled
    And they visit the income adjustments page via the left nav
    Given the user answers yes to having income adjustments
    Then the divorce agreement copy should show

  Scenario: Health Savings Account glossary display
    Given the user answers yes to having income adjustments
    Then the health_savings_account have glossary link
    Then the health_savings_account have glossary content

  Scenario: Alimony Paid glossary does not display
    Given the user answers yes to having income adjustments
    Then the alimony_paid does not have glossary link
