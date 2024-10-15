Feature: Insured Plan Shopping on Individual market
  Background:
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    Given FAA no_coverage_tribe_details feature is enabled
    Given Individual has not signed up as an HBX user
    And Individual visits the Consumer portal during open enrollment
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    And the user registers as an individual
    
  Scenario: New user creates an account
    Given Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't fill it out completely
    Then Individual clicks on continue
    Then Individual sees form to enter personal information
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: New user creates an account and forgets to check a box
    Given Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't check every box
    And Individual clicks on continue
    Then the user will have to accept alert pop up for missing field
    Then Individual sees form to enter personal information
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: Consumer clicks the personal information page continue button
    Given the Continue button is visible on the Account Setup page
    And Individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information
    And the continue button has data disabled attribute
    And Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: Consumer clicks the personal match page continue button
    Given the Continue button is visible on Account Setup page
    And the continue button has a data disabled attribute
    And Individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information

  Scenario: Consumer clicks the personal match page continue button with contact preference text
    Given bs4_consumer_flow feature is enabled
    Given EnrollRegistry contact_method_via_dropdown feature is disabled
    Given the Continue button is visible on Account Setup page
    And Individual clicks on the Continue button of the Account Setup page with bs4 enabled
    And Individual sees form to enter personal information with invalid phone number
    And Individual selects contact text check box
    Then Individual clicks on continue
    Then Individual should see an message warning about invalid phone

  Scenario: Consumer clicks the personal match page continue button without contact preference text
    Given bs4_consumer_flow feature is enabled
    Given EnrollRegistry contact_method_via_dropdown feature is disabled
    Given the Continue button is visible on Account Setup page
    And Individual clicks on the Continue button of the Account Setup page with bs4 enabled
    And Individual sees form to enter personal information with invalid phone number
    Then Individual clicks on continue
    Then Individual should see an message warning about invalid phone
