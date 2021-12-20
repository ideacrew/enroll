Feature: Consumer agrees RIDP verification process

  Background: Individual RIDP Verification process
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    Then Individual sees form to enter personal information
    When Individual clicks on continue

  Scenario: New insured user chooses I Agree on Auth and Consent Page
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    Then the consumer will be directed to answer the Experian Identity Proofing questions

  Scenario: New insured user chooses I Agree on Auth and Consent Page and user uploaded identity on failed experain page
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    Then an uploaded identity verification in REVIEW status is present

  Scenario: New insured user chooses I Agree on Auth and Consent Page and user uploaded application on failed experian page
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    Then an uploaded application in REVIEW status is present
   
  Scenario: New insured user chooses I Agree on Auth and Consent Page and continue button is disabled
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And  an Experian Error screen appears for the consumer
    And Application verification is OUTSTANDING
    And Identity verification is OUTSTANDING
    Then the CONTINUE button is functionally DISABLED
    And visibly DISABLED
