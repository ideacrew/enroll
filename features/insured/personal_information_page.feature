Feature: Insured Plan Shopping on Individual market
  Background:
    Given the FAA feature configuration is enabled
    Given Individual has not signed up as an HBX user
    And Individual visits the Consumer portal during open enrollment
    
  Scenario: New user creates an account
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When the user registers as an individual
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't fill it out completely
    Then Individual clicks on continue
    Then Individual sees form to enter personal information
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

  Scenario: New user creates an account and forgets to check a box
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When the user registers as an individual
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information but doesn't check every box
    Then Individual clicks on continue
    Then Individual sees form to enter personal information
    Then Individual clicks on continue
    Then Individual agrees to the privacy agreeement

