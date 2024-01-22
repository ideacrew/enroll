Feature: Contrast level AA is enabled - Consumer goes to verify identity questions page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    When I visit the Insured portal
    And the user creates a Consumer role account
    When the consumer clicks on the privacy continue button
    And Individual fills in personal info
    When Individual clicks the personal info continue button
    When Individual clicks the personal info continue button
    And Individual sees form to enter personal information
    When Individual clicks the personal info continue button
    And Individual agrees to the privacy agreeement
    Then the page passes minimum level aa contrast guidelines
