Feature: Person with Dual Role(Broker and Consumer Role) navigation using My Portals link on top right.

  Background: A person with consumer role and broker role exists
    Given a person exists with a user
    And this person has a consumer role with failed or pending RIDP verification
    And the last visited page is RIDP agreement
    And this person has an unapproved broker role and broker agency profile
    And the broker role is approved, broker agency staff is created and is associated to the broker agency profile

  Scenario: User logs into the account when the RR feature is enabled
    Given broker_role_consumer_enhancement feature is enabled
    And the Dual Role user logs into their account
    And lands on RIDP agreement page
    Then the user will be able to see My Portals dropdown
    And the user clicks My Portals dropdown
    Then the user will see My Insured Portal Link and My Broker Agency Portal Link
    And the user clicks the Broker Agency Profile link with legal name
    Then the user navigates to the Broker Agency Profile
    And the user clicks My Portals dropdown
    Then the user will see My Insured Portal Link and My Broker Agency Portal Link
    And the user clicks the My Insured Portal link
    And the user navigates to Consumer Role account to RIDP agreeement page
    And Individual logs out

  Scenario: User logs into the account when the RR feature is disabled
    Given broker_role_consumer_enhancement feature is disabled
    And the Dual Role user logs into their account
    And lands on RIDP agreement page
    Then the user will be able to see My Broker Agency Portal Link
    And the user clicks the Broker Agency Profile link
    And the user navigates to the Broker Agency Profile
    Then the user will be able to see My Broker Agency Portal Link
    Then the user does not see My Insured Portal Link
    And Individual logs out
