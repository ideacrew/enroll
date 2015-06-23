@watir @screenshots
Feature: Create Broker Agency

    Scenario: A Broker Agency Representative has not signed up on the HBX
      Given I haven't signed up as an HBX user
      When I visit the Broker Agency portal
        And I sign up with valid user data
      Then I should see a successful sign up message
        And I should see an initial form to enter information about my Broker Agency and myself
      When I complete the Broker Agency form
      Then I should see the Broker Agency Landing Page
