Feature: Contrast level AA is enabled - Consumer goes to the extended personal info page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    When I visit the Insured portal
    And the user creates a Consumer role account
    When the consumer clicks on the privacy continue button
    And Individual fills in personal info
    And Individual clicks the personal info continue button
    And Individual clicks the personal info continue button
    Then the page passes minimum level aa contrast guidelines