Feature: As a Super Admin I will have the ability to see and access "Send Secure Message" action on employers tab

  Background: Setup site, employer, and benefit application
    Given a ACA site exists with a benefit market
    And there is an employer ABC Widgets
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer

  Scenario: HBX Staff with Super Admin sub roles should see Send Secure Message button
    Then the user will see the Send Secure Message button

  Scenario: HBX Staff with Super Admin sub roles should see the Send Secure Message Form
    When the user clicks the Send Secure Message button for this Employer
    Then the user will see the Send Secure Message option form

  Scenario: Super Admin sub roles clicks the Send Secure Message Form recipient field should be populated
    When the user clicks the Send Secure Message button for this Employer
    Then the Recipient field should auto populate with the Employer groups name ABC Widgets

  Scenario: Send Secure Message Form should have recipient and subject fields as "required"
    When the user clicks the Send Secure Message button for this Employer
    Then the Secure message form should have Subject and Content as required fields

  Scenario: Secure message form should be closed out when Super Admin sub roles click cancel button
    When the user clicks the Send Secure Message button for this Employer
    And the user clicks cancel button
    Then the user will not see the Send Secure Message option form
