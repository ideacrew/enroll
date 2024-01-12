Feature: Contrast level AA is enabled - Consumer goes to the applications page
  Scenario: Consumer visits the Applications Page
    Given the contrast level aa feature is enabled
    Given the FAA feature configuration is enabled
    Given individual Qualifying life events are present
    Given Individual has not signed up as an HBX user
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    And Individual sees form to enter personal information
    When Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    Then Individual does not apply for assistance and clicks continue
    And Individual clicks on the Continue button of the Family Information page
    When Individual click the "Had a baby" in qle carousel
    And Individual selects a current qle date
    Then Individual should see confirmation and continue
    And Individual clicks on continue button on Choose Coverage page
    And Individual select three plans to compare
    Then Individual should not see any plan which premium is 0
    When Individual selects a plan on plan shopping page
    And Individual clicks on purchase button on confirmation page
    And Individual clicks on continue
    Then Individual should land on Home page
    Given the Applications link is visible
    And the consumer clicks the Applications link
    Then the page passes minimum level aa contrast guidelines
