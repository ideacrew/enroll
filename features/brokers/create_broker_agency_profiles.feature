@watir @keep_browser_open @screenshots
Feature: Create Broker Agency
  In order to support individual and SHOP market clients, brokers must create and manage an account on the HBX for their organization.  Such organizations are referred to as a Broker Agency
  A Broker Representative
  Should be able to create a Broker Agency account

  Scenario: Broker Representative has not signed up on the HBX
    Given I haven't signed up as an HBX user
    When I visit the HBX Broker Agency portal
    And I sign up with valid user data
    Then I should see a successful sign up message
    And I should see an initial form to enter broker agency information
    And I should see a second fieldset to enter more broker agency information
    And I should see a third fieldset to enter primary broker information
    And I should see a radio button asking if i'm the primary broker
    And I should see a fourth fieldset to enter my name, email and phone that is only required to complete if i'm not the primary broker
    And My user data from existing the fieldset values are prefilled using data from my existing Person record
    When I click on create broker agency button
    Then I should see a successful broker create message