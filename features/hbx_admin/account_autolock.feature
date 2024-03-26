Feature: Admin account will be expired if it is not used for set period
  Background:
    Given EnrollRegistry admin_account_autolock feature is enabled
  
  Scenario: Admin logs in after 60 days
    Given that a user with a HBX staff role with super_admin subrole exists
    And admin last signed in more than 60 days ago
    When Hbx Admin logs on to the Hbx Portal
    Then admin should not be able to log in
  
  Scenario: Admin logs in before 60 days
    Given that a user with a HBX staff role with super_admin subrole exists
    When Hbx Admin logs on to the Hbx Portal
    Then admin should be signed in successfully

  Scenario: Consumer logs in
    Given a consumer exists
    And consumer last signed in more than 60 days ago
    And the consumer is logged in
    And consumer visits home page
    Then the consumer should be signed in successfully