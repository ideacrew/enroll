Feature: Contrast level AA is enabled - Consumer goes to the create account page
  Scenario: Consumer visits the create account page
    Given the contrast level aa feature is enabled
    When the user visits the Insured portal
    Then the page passes minimum level aa contrast guidelines
