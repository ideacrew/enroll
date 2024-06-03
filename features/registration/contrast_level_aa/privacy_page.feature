Feature: Contrast level AA is enabled - Consumer goes to the privacy and use of info page
  Scenario: Consumer visits the privacy and use of info page
    Given the contrast level aa feature is enabled
    When the user visits the Insured portal
    And the user creates a Consumer role account
    Then the page passes minimum level aa contrast guidelines
