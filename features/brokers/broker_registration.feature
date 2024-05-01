Feature: Broker Agency Registration

  Scenario: Primary Broker has not signed up on the HBX
    Given the shop market configuration is enabled
    And EnrollRegistry broker_attestation_fields feature is disabled
    And EnrollRegistry broker_approval_period feature is enabled
    And EnrollRegistry broker_invitation feature is enabled
    Given a CCA site exists with a benefit market
    When Primary Broker visits the HBX Broker Registration form
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information
    And And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see broker registration successful message

    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click approve broker button
    Then Hbx Admin should see the broker successfully approved message
    And Hbx Admin logs out

    Then Primary Broker should receive an invitation email
    When Primary Broker visits invitation url in email
    Then Primary Broker should see the create account page
    When Primary Broker registers with valid information
    Then they should see a welcome message


  @broken
  Scenario: When the broker is hired as a census employee and registration is complete through employee role
    Given a CCA site exists with a benefit market
    # These steps will set up:
    # Given Primary Broker Ricky Martin exists
    When Primary Broker visits the HBX Broker Registration form
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information
    And And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see broker registration successful message

    Given Hbx Admin exists
    When Hbx Admin logs on to the Hbx Portal
    And Hbx Admin is on Broker Index of the Admin Dashboard
    Then Hbx Admin is on Broker Index and clicks Broker Applicants
    When Hbx Admin clicks on the current broker applicant show button
    Then Hbx Admin should see the broker application with carrier appointments
    When Hbx Admin click approve broker button
    Then Hbx Admin should see the broker successfully approved message
    And Hbx Admin logs out

    # Set up employer
    And benefit market catalog exists for enrollment_open renewal employer with health benefits
    And there is an employer Acme Inc.
    And renewal employer Acme Inc. has active and renewal enrollment_open benefit applications
    And there is a census employee record and employee role for Patrick Doe for employer Acme Inc.
    And census employee Patrick Doe is a newly_designated_eligible employee
    And census employee Patrick Doe has a user record
    And this employer Acme Inc. has first_of_month rule
    And user Patrick Doe logs into the portal
    Then Employee should click on Manage Family button
    Then Employee should click on the Personal Tab link
    Then Employee should not see phone main field in the personal information fields
    And Employee Ricky Martin should only have phone with work kind

  Scenario: Broker registration without NPN
    Given the shop market configuration is enabled
    And EnrollRegistry broker_attestation_fields feature is disabled
    And EnrollRegistry broker_approval_period feature is enabled
    And EnrollRegistry broker_invitation feature is enabled
    Given a CCA site exists with a benefit market
    When Primary Broker visits the HBX Broker Registration form
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information without npn
    And And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see broker npn validation error message

  Scenario: Broker registration with already used NPN and then pass empty NPN
    Given the shop market configuration is enabled
    And EnrollRegistry broker_attestation_fields feature is disabled
    And EnrollRegistry broker_approval_period feature is enabled
    And EnrollRegistry broker_invitation feature is enabled
    Given a CCA site exists with a benefit market
    And broker with a specific NPN already exists
    When Primary Broker visits the HBX Broker Registration form
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form
    When Primary Broker enters personal information with specific NPN
    And And Primary Broker enters broker agency information for SHOP markets
    And Primary Broker enters office location for default_office_location
    Then Primary Broker should see the NPN already taken message
    When Primary Broker delete NPN and submit form
    Then Primary Broker should see broker npn validation error message
