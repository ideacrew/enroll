Feature: Contrast level AA is enabled - Consumer goes to the create account page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    When I visit the Insured portal
    Then the page passes minimum level aa contrast guidelines
