# frozen_string_literal: true

Feature: UI Validations for Contact Method
    Background:
        Given bs4_consumer_flow feature is enabled
        Given Adtl contact required for text feature is enabled
        Given Contact method via dropdown feature is NOT enabled
        Given Individual has not signed up as an HBX user
        Given the FAA feature configuration is enabled

    Scenario: Individual signs up with Text only contact method
        When Individual visits the Consumer portal during open enrollment
        Then Individual creates a new HBX account
        Then Individual should see a successful sign up message
        And Individual sees Your Information page
        And Individual fills in info required and selects text only as contact option
        When Individual clicks on continue
        Then Individual should see an error message warning about text

    Scenario: Individual signs up with Text only contact method
        When Individual visits the Consumer portal during open enrollment
        Then Individual creates a new HBX account
        Then Individual should see a successful sign up message
        And Individual sees Your Information page
        And Individual fills in info required and selects no contact option
        When Individual clicks on continue
        Then Individual should see an error message warning about no contact method