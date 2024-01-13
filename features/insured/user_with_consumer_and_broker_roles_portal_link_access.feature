Feature: Person with Dual Role(Broker and Consumer Role) access to the top right portal link.

  Background: A person with consumer role and broker role exists
    Given a person exists with a user
    And this person has a consumer role with failed or pending RIDP verification
    And the last visited page is RIDP agreement
    And this person has an unapproved broker role and broker agency profile

  Scenario: User logs into the account when the RR feature is enabled
    Given broker_role_consumer_enhancement feature is enabled
    And the broker role is approved, broker agency staff is created and is associated to the broker agency profile
    And the Dual Role user logs into their account
    And lands on RIDP agreement page
    Then the user will be able to see My Portals dropdown
    And Individual logs out

  Scenario: User logs into the account when the RR feature is disabled
    Given broker_role_consumer_enhancement feature is disabled
    And the Dual Role user logs into their account
    And lands on RIDP agreement page
    Then the user will not be able to see My Portals dropdown
    And Individual logs out
