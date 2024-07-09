# frozen_string_literal: true

Feature: Contrast level AA is enabled - existing consumer visits the my expert page
    Background:
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled
    And an IVL Broker Agency exists
    And the broker Max Planck is primary broker for IVL Broker Agency
    And Individual has not signed up as an HBX user
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information
    When the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    And Individual has broker assigned to them
    And Individual visits home page
    And Individual clicks on the Get Help Signing Up button

  Scenario: the user visits the my expert page
    And Individual clicks on the Help from an Expert link
    And Individual selects a broker
    And Individual clicks on Select this Broker button
    And Individual clicks on close button
    And the page is refreshed
    And Individual clicks on the My Broker link
    Then the page passes minimum level aa contrast guidelines

  Scenario: User selects a broker in the Help Me Sign Up widget in families home page
    And Individual clicks on the Help from an Expert link
    And Individual selects a broker
    Then Individual confirms a broker
    And Individual clicks on close button
    And the page is refreshed
    And Individual sees your expert widget
