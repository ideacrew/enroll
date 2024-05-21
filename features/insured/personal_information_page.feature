Feature: Insured Plan Shopping on Individual market
  Background:
    Given the FAA feature configuration is enabled
    Given FAA no_coverage_tribe_details feature is enabled
    Given Individual has not signed up as an HBX user
    And Individual visits the Consumer portal during open enrollment
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When the user registers as an individual
    
  Scenario: New user creates an account
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't fill it out completely
    Then Individual clicks on continue
    Then Individual sees form to enter personal information
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: New user creates an account and forgets to check a box
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't check every box
    Then Individual clicks on continue
    And the user will have to accept alert pop up for missing field
    Then Individual fills in missing fields
    Then Individual sees the continue button is enabled
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: Consumer clicks the personal information page continue button
    And the Continue button is visible on the Account Setup page
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information
    Then the continue button has data disabled attribute
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement
