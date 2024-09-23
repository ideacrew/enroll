Feature: Contrast level AA is enabled - Review your application page functionality

  Background: Review your application page
    Given the contrast level aa feature is enabled
    And a consumer exists
    And is logged in
    And the FAA feature configuration is enabled
    And the user will navigate to the FAA Household Info page
    And all applicants are in Info Completed state with all types of income
    And the user clicks CONTINUE
    Then the user is on the Review Your Application page

  Scenario: Submit button is enabled when required checkboxes are checked and name is signed
    Then the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast
