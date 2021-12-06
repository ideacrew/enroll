Feature: CSR finishes shopping for Individual

  Scenario: Customer Service Representative continues new consumer application
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    Given a CSR exists
    When Individual visits the Insured portal outside of open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    And Individual sees form to enter personal information
    And Individual clicks on continue
    And Individual asks for help
    And Individual logs out
    When CSR logs on to the HBX portal
    Then CSR should see the Agent Portal
    When CSR clicks on the Inbox tab
    And CSR opens the most recent Please Contact Message
    And CSR clicks on Resume Application via phone
    And CSR agrees to the privacy agreeement
    And CSR answers the questions of the Identity Verification page and clicks on submit
    Then CSR is on the Help Paying for Coverage page
    When CSR does not apply for assistance and clicks continue
    And CSR clicks on the header link to return to CSR page
    Then CSR should see the Agent Portal
