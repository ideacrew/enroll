Feature: Admin will be signed out if concurrent logins are detected
  Background:
    Given the prevent_concurrent_sessions feature is enabled
    Given that a user with a HBX staff role with hbx_tier3 subrole exists

  Scenario: Admin logs in from a second location
    Given admin logs in on browser 1
    And admin logs in on browser 2
    And admin attempts to navigate on browser 1
    Then admin on browser 1 should see the logged out due to concurrent session message

  Scenario: Broker person logs in from a second location
    Given broker logs in on browser 1
    And broker logs in on browser 2
    And broker attempts to navigate on browser 1
    Then broker on browser 1 should see the logged out due to concurrent session message
