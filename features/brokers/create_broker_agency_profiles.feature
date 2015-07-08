@watir @screenshots
Feature: Create Broker Agency
  In order to support individual and SHOP market clients, brokers must create and manage an account on the HBX for their organization.  Such organizations are referred to as a Broker Agency
  A Broker Representative
  Should be able to create a Broker Agency account

  Scenario: Broker Representative has not signed up on the HBX
    Given I haven't signed up as an HBX user
    When I visit the HBX Broker Agency portal
    And I should see an initial form to enter personal information
    And I should see a second fieldset to enter broker agency information
    And I should see a third fieldset to enter more office location information
    When I click on create broker agency button
    Then I should see a successful broker create message