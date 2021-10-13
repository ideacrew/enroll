Feature: Broker Agency Registration

  Scenario: Registering Primary Broker with HBX
    And EnrollRegistry broker_attestation_fields feature is disabled
    And EnrollRegistry allow_alphanumeric_npn feature is enabled
    Given a CCA site exists with a benefit market
    When a Primary Broker visits the HBX Broker Registration form POM
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form POM
    When Primary Broker enters personal information POM
    And Primary Broker enters broker agency information POM
    Then Primary Broker should see the registration submitted successful message

  Scenario: NPN Already Taken - Should throw an error
    And EnrollRegistry broker_attestation_fields feature is disabled
    Given a CCA site exists with a benefit market
    And broker with a specific NPN already exists
    When a Primary Broker visits the HBX Broker Registration form POM
    Given Primary Broker has not signed up as an HBX user
    Then Primary Broker should see the New Broker Agency form POM
    When Primary Broker enters personal information POM
    And Primary Broker enters broker agency information POM
    Then Primary Broker should see the NPN already taken message
