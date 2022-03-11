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
    And the consumer is logged in
    And EnrollRegistry location_residency_verification_type feature is enabled
    And consumer has outstanding verification and unverified enrollments
    When the consumer visits verification page
    Then consumer should see Verification Due date label
    And consumer should see Documents We Accept link
    And the consumer should see documents verification page

  Scenario: Consumer is fully_verified should see verification types
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types have to be visible

  Scenario: Consumer is from Curam and is fully verified and shows verification types as verified
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And the consumer should see documents verification page
    Then verification types should display as verified state

  Scenario: Admin clicks on documents tab for Curam verified person
    Given a consumer exists
    And the consumer is logged in
    When the consumer is completely verified from curam
    Then the consumer visits verification page
    And consumer logs out
    When an HBX admin exists
    And clicks on the person in families tab
    Then verification types should display as external source
