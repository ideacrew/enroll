Feature: Contrast level AA is enabled - Consumer goes to the home page
  Scenario: Consumer visits the home page
    Given the contrast level aa feature is enabled
    Then the page passes minimum level aa contrast guidelines
