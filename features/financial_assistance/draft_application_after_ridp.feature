Feature: Send users to draft application created by account transfer after RIDP

  Background: Individual RIDP Verification process    
    Given the FAA feature configuration is enabled
    And EnrollRegistry tobacco_user_field feature is enabled
    And FAA draft_application_after_ridp feature is enabled
    And Individual has draft application that was created by account transfer
    When Individual visits the Consumer portal during open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual with personal info matching the account transfer
    And Individual clicks on continue
    And Individual fills out the personal information form
    And Individual clicks on continue

# Note: what is alternative flow to application page from failed experian page???
Scenario: New insured user chooses I Agree on Auth and Consent Page and Continue Application on failed experain page
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    And the user clicks the Continue Application button
    Then the user should see the application Family Information page for the existing draft 