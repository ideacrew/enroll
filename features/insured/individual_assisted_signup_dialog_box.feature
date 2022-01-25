Feature: Insured Plan Shopping on Individual Assisted market

 Background: Individual market setup
    Given EnrollRegistry contact_method_via_dropdown feature is enabled
    And the FAA feature configuration is enabled
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

  Scenario: Validation of the dailog box when selecting a non silver plan with eligiblity
    And the individual answers the questions of the Identity Verification page and clicks on submit
    And the individual clicks on the Continue button of the Household Info page
    When taxhousehold info is prepared for aptc user with selected eligibility
    And the individual does not apply for assistance and clicks continue
    And the individual clicks on the Continue button of the Household Info page
    # And the individual enters a SEP
    And the individual clicks the Continue button of the Group Selection page
    When the individual sets APTC amount
    And the individual selects a non silver plan on Plan Shopping page
    Then the individual should see the modal pop up for eligibility