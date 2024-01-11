Feature: Contrast level AA is enabled - User is not applying for financial assistance
  Background:
    Given the contrast level aa feature is enabled
    Given the FAA feature configuration is enabled
    When the user is applying for a CONSUMER role
    And the primary member has filled mandatory information required
    And the primary member authorizes system to call EXPERIAN
    And system receives a positive response from the EXPERIAN
    And the user answers all the VERIFY IDENTITY  questions
    When the user clicks on submit button
    And the Experian returns a VERIFIED response
    Then the user will navigate to the Help Paying for Coverage page

  Scenario: Consumer is not applying for financial assistance
    Given the user navigates to the "Household Info" page with "no" selected
    When the user clicks on add member button
    Then the page should be axe clean excluding "a[disabled], .disabled" according to: wcag2aa; checking only: color-contrast
