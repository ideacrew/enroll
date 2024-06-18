Feature: Insured with more than two dependents

  Background: Individual market setup
    Given bs4_consumer_flow feature is disable
    Given an Individual has not signed up as an HBX user
    And the FAA feature configuration is enabled

  @nightly
  Scenario: Individual signs up with more than two dependents
    Given the user visits the Consumer portal during open enrollment
    When the user creates a Consumer role account
    And the user sees Your Information page
    And user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    And the individual sees form to enter personal information
    And the individual clicks continue on the personal information page
    And the individual agrees to the privacy agreeement
    And the person named Patrick Doe is RIDP verified
    And the individual answers the questions of the Identity Verification page and clicks on submit
    When the individual is on the Help Paying for Coverage page
    And the individual does not apply for assistance and clicks continue
    And Individual clicks on Add New Person
    And Individual fills in the form
    Then Individual confirms dependent info
    And Individual clicks on Add New Person
    And Individual fills in the form
    Then Individual confirms dependent info
    And Individual clicks on Add New Person
    And Individual fills in the form
    Then Individual confirms dependent info
    Then Individual should see three dependents on the page
