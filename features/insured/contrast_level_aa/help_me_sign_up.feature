Feature: Contrast level AA is enabled - Help Me Sign Up Modal

  Background:
    Given the contrast level aa feature is enabled
    And an IVL Broker Agency exists
    And the broker Max Planck is primary broker for IVL Broker Agency
    And Individual has not signed up as an HBX user
    And the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on the Continue button of the Family Information page
    And Individual clicks on continue button on Choose Coverage page
    And Individual clicks on the Help Me Sign Up link

  Scenario: User opens the Help Me Sign Up modal
    And Individual clicks on the Help from an Expert link
    Then the page passes minimum level aa contrast guidelines

  Scenario: User selects a broker in the Help Me Sign Up modal
    And Individual clicks on the Help from an Expert link
    And Individual selects a broker
    Then the page passes minimum level aa contrast guidelines
