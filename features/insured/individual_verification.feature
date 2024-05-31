Feature: Consumer verification process

# TO DO: confirm and update last two steps as far as what is the expected residency link to finish refactor 
@flaky
Scenario: Outstanding verification
    Given Individual has not signed up as an HBX user
    Given the FAA feature configuration is enabled
    When Individual visits the Consumer portal during open enrollment
    And Individual creates a new HBX account
    Then Individual should see a successful sign up message
    And Individual sees Your Information page
    When user registers as an individual
    And Individual clicks on continue
    And Individual sees form to enter personal information
    And Individual clicks on continue
    And Individual agrees to the privacy agreeement
    And Individual answers the questions of the Identity Verification page and clicks on submit
    Then Individual is on the Help Paying for Coverage page
    When Individual does not apply for assistance and clicks continue
    And Individual clicks on continue
    And Individual clicks on continue button on Choose Coverage page
    When Individual selects a plan on plan shopping page
    And Individual clicks on purchase button on confirmation page
    And Individual clicks on Go To My Account button
    And Individual clicks on Documents link
    * I should see page for documents verification

  Scenario: Consumer with outstanding verification and uploaded documents
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    And EnrollRegistry location_residency_verification_type feature is enabled
    And consumer has outstanding verification and unverified enrollments
    When the consumer visits verification page
    Then consumer should see Verification Due date label
    And consumer should see Documents We Accept link
    And the consumer should see documents verification page

  Scenario: Consumer is fully_verified should see verification types
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the consumer is completely verified
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types have to be visible

  Scenario: Consumer is from Curam and is fully verified and shows verification types as verified
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types should display as verified state

  Scenario: Admin clicks on documents tab for Curam verified person
    Given a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And consumer logs out
    When an HBX admin exists
    And clicks on the person in families tab
    Then verification types should display as external source

  Scenario: Consumer has determined Financial Assistance application
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And FAA mec_check feature is enabled
    And a family with financial application and applicants in determined state exists with evidences
    And the user is RIDP verified
    And the user with hbx_staff role is logged in
    When admin visits home page
    And Individual clicks on Documents link
    Then Individual should see cost saving documents for evidences
    And Individual clicks on Actions dropdown
    Then Individual should see view history option
    And Individual clicks on view history
    Then Individual should see request histories and verification types
    And Individual clicks on cancel button
    Then Individual should not see view history table

  Scenario: Admin verifies consumer's income evidence
    Given the FAA feature configuration is enabled
    And FAA display_medicaid_question feature is enabled
    And FAA mec_check feature is enabled
    And a family with financial application and applicants in determined state exists with evidences
    And the user is RIDP verified
    And the user with hbx_staff role is logged in
    When admin visits home page
    And Individual clicks on Documents link
    Then Individual should see cost saving documents for evidences
    And Individual clicks on Actions dropdown
    And Individual clicks on verify
    And Individual Selects Reason
    And Individual clicks on Actions dropdown
    And Individual clicks on view history
    Then Individual should see verification history timestamp

  Scenario: Consumer and Admin viewing Alive Status verification type
    Given the enable_alive_status feature is enabled
    And a consumer exists
    And the user is RIDP verified
    And the consumer is logged in
    And the consumer is completely verified
    When the consumer visits verification page
    Then the consumer should not see the Alive Status verification type
    When the consumer's Alive Status is moved to outstanding
    And the page is refreshed
    Then the consumer should see the Alive Status verification type
    When the consumer logs out
    And the consumer's Alive Status is moved to verified
    When an HBX admin exists
    And clicks on the person in families tab
    Then the admin should see the Alive Status verification type

  Scenario: Selectric is enabled
    Given a consumer exists
    And the user is RIDP verified
    And the user with hbx_staff role is logged in
    When admin visits home page
    And Individual clicks on Documents link
    Then the selectric class is visible
