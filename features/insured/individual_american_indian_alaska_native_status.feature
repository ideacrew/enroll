# frozen_string_literal: true

Feature: UI Validations for American Indian Alaska Native
    Background:
        Given bs4_consumer_flow feature is disable
        Given AI AN Details feature is enabled
        Given Featured Tribe Selection feature is enabled
        Given Individual has not signed up as an HBX user
        Given the FAA feature configuration is enabled
    
    Scenario: Individual signs up with American Indian status with featured tribe
        When Individual visits the Consumer portal during open enrollment
        Then Individual creates a new HBX account
        Then Individual should see a successful sign up message
        And Individual sees Your Information page
        When user registers as an individual
        And the individual clicks on the Continue button of the Account Setup page
        And Individual enter personal information with american indian alaska native status with featured tribe


    Scenario: Individual signs up with American Indian status with other tribe
        When Individual visits the Consumer portal during open enrollment
        Then Individual creates a new HBX account
        Then Individual should see a successful sign up message
        And Individual sees Your Information page
        When user registers as an individual
        And the individual clicks on the Continue button of the Account Setup page
        And Individual enter personal information with american indian alaska native status with other tribe

