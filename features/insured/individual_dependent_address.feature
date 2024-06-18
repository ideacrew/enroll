Feature: Insured Plan Shopping on Individual market
  Background:
    Given bs4_consumer_flow feature is disable
    Given the FAA feature configuration is enabled
    Given Individual has not signed up as an HBX user
    And Individual visits the Consumer portal during open enrollment
  
  Scenario: New insured user adds dependent address  
    When Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    When Individual clicks on Add New Person
    And Individual fills in the form
    Then Individual adds address for dependent