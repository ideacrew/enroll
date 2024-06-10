Feature: Contrast level AA is enabled - Consumer goes to verify identity questions page
  Scenario: Consumer visits the verify identity questions page
    Given the contrast level aa feature is enabled
    When the user visits the Insured portal
    And the user creates a Consumer role account
    When the consumer clicks on the privacy continue button
    And Individual fills in personal info
    When Individual clicks the personal info continue button
    When Individual clicks the personal info continue button
    And Individual sees form to enter personal information
    When Individual clicks the personal info continue button
    And Individual agrees to the privacy agreeement
    And the individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    Then the page passes minimum level aa contrast guidelines
