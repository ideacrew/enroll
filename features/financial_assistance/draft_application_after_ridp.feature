Feature: Send users to draft application created by account transfer after RIDP

  Background: Individual RIDP Verification process    
    Given the FAA feature configuration is enabled
    # And individual has draft application that was created by account transfer
    Given Individual has not signed up as an HBX user
    # ^^^rewrite this b/c we need to match new User to ATP'd Person in db
    When Individual visits the Insured portal outside of open enrollment 
    # ^^^maybe? (probably remove)
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    Then Individual sees form to enter personal information
    When Individual clicks on continue

# Note: what is alternative flow to failed experian page???
Scenario: New insured user chooses I Agree on Auth and Consent Page and Continue Application on failed experain page
    Given that the consumer has navigated to the AUTH & CONSENT page
    When the consumer selects “I Agree”
    And that the consumer has answered the Experian Identity Proofing questions
    When Experian is unable to verify Identity for the consumer
    And an Experian Error screen appears for the consumer
    # And the user clicks the Continue Application button
    # Then the user should see the Family Information page for the existing draft 