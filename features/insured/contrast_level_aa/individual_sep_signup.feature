Feature: Contrast level AA is enabled - Insured Plan Shopping on Individual market
  Background:
    Given the contrast level aa feature is enabled
    And the FAA feature configuration is enabled
    Given individual Qualifying life events are present
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    And Individual sees form to enter personal information

 Scenario: New insured user purchases on individual market thru qualifying life event
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    And Individual clicks on the Continue button of the Family Information page
    When Individual click the "Had a baby" in qle carousel
    And Individual selects a current qle date
    Then the page passes minimum level aa contrast guidelines
