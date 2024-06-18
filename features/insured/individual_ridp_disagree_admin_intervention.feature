Feature: Consumer disagrees RIDP verification process

  Background: Individual RIDP Verification process
    Given bs4_consumer_flow feature is disable
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    Then Individual sees form to enter personal information
    And the individual clicks continue on the personal information page
 
  Scenario: Application is verified by admin
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded application in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded application in VERIFIED status is present
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED

  Scenario: Not Allowing admin to continue on the ridp doc upload page until ID is verified
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    Then Individual logs out
    Given an HBX admin exists
    When the Admin clicks “Continue” on the doc upload page
    Then the Admin is unable to complete the application for the consumer until ID is verified

  Scenario: Identity is verified by admin
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded identity verification in REVIEW status is present
    And an uploaded application in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded Identity verification in VERIFIED status is present
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally ENABLED
    And visibly ENABLED

  Scenario: Both Identity and Application are verified by admin
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded identity verification in REVIEW status is present
    And an uploaded application in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded Identity verification in VERIFIED status is present
    And an uploaded application in VERIFIED status is present
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally ENABLED
    And visibly ENABLED