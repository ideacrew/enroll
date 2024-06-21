Feature: Consumer disagrees RIDP verification process

  Background: Individual RIDP Verification process
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

  Scenario: User chooses I Disagree on Auth and Consent Page and directed to document upload and see Identity and application as outstanding
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And Application verification is OUTSTANDING
    And Identity verification is OUTSTANDING
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED

  Scenario: User uploads document for Application
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded application in REVIEW status is present
    And Identity verification is OUTSTANDING
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED
  
  Scenario: User uploads document to verify Identity
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded identity verification in REVIEW status is present
    And Application verification is OUTSTANDING
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED

  Scenario: User uploads both Identity and Application
    Given that the consumer has “Disagreed” to AUTH & CONSENT
    And the consumer is on the DOCUMENT UPLOAD page
    And an uploaded identity verification in REVIEW status is present
    And an uploaded application in REVIEW status is present
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED

  