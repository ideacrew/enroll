Feature: Insured Plan Shopping on Individual market

  Background:
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    Then Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    When Individual clicks on continue
    And Individual sees form to enter personal information

  Scenario: New insured user purchases on individual market
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on the Continue button of the Family Information page
    And Individual clicks on continue button on Choose Coverage page
    And Individual select three plans to compare
    And Individual should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And Individual clicks on purchase button on confirmation page
    Then Individual clicks on the Continue button to go to the Individual home page

  Scenario: New insured user purchases on individual market and click on 'Make changes' button on enrollment
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual fills in the form
    And Individual clicks on confirm member
    And Individual clicks on the Continue button of the Family Information page
    And Individual clicks on continue button on Choose Coverage page
    And Individual select three plans to compare
    And Individual should not see any plan which premium is 0
    And Individual selects a plan on plan shopping page
    And Individual clicks on purchase button on confirmation page
    And Individual clicks on the Continue button to go to the Individual home page
    When Individual clicks on Make Changes from Actions tab
    Then Individual should not see any plan which premium is 0
