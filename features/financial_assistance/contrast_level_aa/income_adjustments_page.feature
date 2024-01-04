Feature: Contrast level AA is enabled - Start a new Financial Assistance Application and fills out Income Adjustments form

  Background: User logs in and visits applicant's income adjustments page
    Given the contrast level aa feature is enabled
    Given EnrollRegistry crm_update_family_save feature is disabled
    Given EnrollRegistry crm_publish_primary_subscriber feature is disabled
    Given divorce agreement year feature is disabled
    Given a consumer, with a family, exists
    And is logged in
    And a benchmark plan exists
    And the FAA feature configuration is enabled
    Given FAA income_and_deduction_date_warning feature is enabled
    When the user will navigate to the FAA Household Info page
    And they click ADD INCOME & COVERAGE INFO for an applicant
    Then they should be taken to the applicant's Tax Info page
    And they visit the income adjustments page via the left nav

  Scenario: User answers no to having income adjustments
    Given the user answers no to having income adjustments
    Then the income adjustments choices should not show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: User answers yes to having other income
    Given the user answers yes to having income adjustments
    Then the income adjustments choices should show
    Then the divorce agreement copy should not show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast

  Scenario: Income adjustments form shows after checking an option
    Given the user answers yes to having income adjustments
    And the user checks a income adjustments checkbox
    Then the income adjustments form should show
    And the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast
