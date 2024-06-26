Feature: Contrast level AA is enabled - Insured Plan Shopping with SEP
  Background:
    Given bs4_consumer_flow feature is enabled
    Given the contrast level aa feature is enabled
    Given the FAA feature configuration is enabled
    Given individual Qualifying life events are present
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    And Individual sees form to enter personal information

 Scenario: New insured user purchases on individual market thru qualifying life event
    And the individual clicks continue on the personal information page
    And Individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    And Individual clicks on the Continue button of the Family Information page
    When Individual click the "Had a baby" in qle carousel
    And Individual selects a current qle date
    Then Individual should see confirmation and continue
    Then the page passes minimum level aa contrast guidelines
