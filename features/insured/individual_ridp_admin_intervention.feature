Feature: Consumer agrees RIDP verification process with Admin intervention

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
    When the individual clicks continue on the personal information page

  Scenario: New insured user chooses I Agree on Auth and Consent Page and uploaded documents for both identity and application and both are verified
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And  an Experian Error screen appears for the consumer
    And an uploaded identity verification in REVIEW status is present
    And an uploaded application in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded Identity verification in VERIFIED status is present on failed experian screen
    And an uploaded application in VERIFIED status is present on failed experian screen
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally ENABLED
    And visibly ENABLED

  Scenario: New insured user chooses I Agree on Auth and Consent Page and uploaded application document
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And  an Experian Error screen appears for the consumer
    And an uploaded application in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded application in VERIFIED status is present on failed experian screen
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED

  Scenario: New insured user chooses I Agree on Auth and Consent Page and uploaded Identity document
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    And an uploaded identity verification in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded Identity verification in VERIFIED status is present on failed experian screen
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then the CONTINUE button is functionally ENABLED
    And visibly ENABLED
  
  Scenario: New insured user chooses I Agree on Auth and Consent Page and uploaded Identity document and admin already purchased a plan
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    And an uploaded identity verification in REVIEW status is present
    Then Individual logs out
    Given an HBX admin exists
    And an uploaded Identity verification in VERIFIED status is present on failed experian screen
    And HBX admin clicks continue after approving Identity document
    And HBX admin does not apply for assistance and clicks continue
    And HBX admin click on continue button on household info form
    When HBX admin click on none of the situations listed above apply checkbox
    And HBX admin click on back to my account button
    Then HBX admin should land on home page
    When HBX admin logs out
    And Individual signed in to resume enrollment
    Then Individual should land on Home page
  
 