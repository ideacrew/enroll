Feature: Insured Plan Shopping on Individual market
  Background:
    Given the FAA feature configuration is enabled
    Given Individual has not signed up as an HBX user
    And the user visits the Consumer portal during open enrollment
  
  Scenario: New insured user adds dependent address  
    When Individual creates a new HBX account
    Then I should see a successful sign up message
    And the user sees Your Information page
    When the user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    Then the individual sees form to enter personal information
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And the individual answers the questions of the Identity Verification page and clicks on submit
    Then the individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    Then Individual should see the dependents form
    When Individual clicks on Add New Person
    And Individual fills in the form
    Then Individual adds address for dependent

  Scenario: New insured user should be on privacy agreeement/verification page on clicking Individual and Family link on respective pages.
    When Individual creates a new HBX account
    Then I should see a successful sign up message
    And the user sees Your Information page
    When the user registers as an individual
    And Individual clicks on continue
    Then the individual sees form to enter personal information
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    Then Individual clicks on Individual and Family link should be on verification page
    
