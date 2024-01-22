Feature: Contrast level AA is enabled - Consumer goes to the privacy and use of info page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    When I visit the Insured portal
    And the user creates a Consumer role account
    Then the page passes minimum level aa contrast guidelines
