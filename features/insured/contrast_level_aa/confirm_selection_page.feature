Feature: Contrast level AA is enabled - Insured Plan Shopping on Individual market

  Background:
    Given the contrast level aa feature is enabled
    Given Individual has not signed up as an HBX user
    And the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When the individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information

  Scenario: New insured user purchases on individual market
    When the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual navigates to Sep Page
    And Individual clicks on continue button on Choose Coverage page
    And Individual select three plans to compare
    And Individual should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    Then the page passes minimum level aa contrast guidelines
