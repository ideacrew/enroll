Feature: Admin will be signed out if concurrent logins are detected
  Background:
    Given the prevent_concurrent_sessions feature is enabled
    Given the preferred_user_access feature is enabled

  Scenario: Admin logs in from a second location
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    Given admin logs in on browser 1
    And admin logs in on browser 2
    And admin attempts to navigate on browser 1
    Then admin on browser 1 should see the logged out due to concurrent session message

  Scenario: Person logs in from a second location
    Given a person exists with a user
    And this person has a consumer role with failed or pending RIDP verification
    Given person logs in on browser 1
    And person logs in on browser 2
    And person attempts to navigate on browser 1
    Then person on browser 1 should see the logged out due to concurrent session message


  Scenario: Admin logs in from a second location while feature is disabled
    Given that a user with a HBX staff role with hbx_tier3 subrole exists
    Given the prevent_concurrent_sessions feature is disabled
    Given the preferred_user_access feature is enabled
    Given admin logs in on browser 1
    And admin logs in on browser 2
    And admin attempts to navigate on browser 1
    Then admin on browser 1 should not see the logged out due to concurrent session message
