Feature: Register as an Broker/GA/Employer
  Users should be able to register as a Broker, General Agency, or Employer from the Registrations Form

Background: Setup site
  Given a CCA site exists with a benefit market

Scenario Outline: Submits the registration form
  Given I'm on the Registration form for a <type>
  When I <option> fill out the <type> form
  And I submit the <type> Registration form
  Then I <status> see a confirmation message for <type>

  Examples:
    | type            | option      | status      |
    | Employer        | completely  | should      |
    | Employer        | partially   | shouldn't   |
