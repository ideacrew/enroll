Feature: Insured Plan Shopping on Individual Assisted market

 Background: Individual market setup
    Given EnrollRegistry contact_method_via_dropdown feature is enabled
    And the FAA feature configuration is enabled
    And the extended_aptc_individual_agreement_message configuration is enabled
    Given EnrollRegistry extended_aptc_individual_agreement_message feature is enabled
    Given an Individual has not signed up as an HBX user
    Given the user visits the Consumer portal during open enrollment
    When the user creates a Consumer role account
    And the user sees Your Information page
    And the user registers as an individual
    And the individual clicks on the Continue button of the Account Setup page
    And the individual sees form to enter personal information
    And the individual clicks on the Continue button of the Account Setup page
    And the individual agrees to the privacy agreeement

  Scenario: Validation of new APTC tool UI changes
    And the individual answers the questions of the Identity Verification page and clicks on submit
    When the individual is on the Help Paying for Coverage page
    And the individual does not apply for assistance and clicks continue
    And the individual clicks on the Continue button of the Household Info page
    # And the individual enters a SEP
    And taxhousehold info is prepared for aptc user
    And has valid csr 0 benefit package with silver plans
    When the individual clicks the Continue button of the Group Selection page
    And the individual is in the Plan Selection page
    Then the individual sees the new APTC tool UI changes
    When the individual sets APTC amount
    And the individual clicks the Reset button
    Then the individual should see the original applied APTC amount
    Then the individual sets APTC amount
    And the individual selects a silver plan on Plan Shopping page
    Then the individual should see the elected APTC amount and click on the Confirm button of the Thank You page
    And the individual should see the APTC amount on the Receipt page
    And Individual clicks on the Continue button to go to the Individual home page
    Then the individual should see the elected aptc amount applied to enrollment in the Individual home page
    Then the individual logs out