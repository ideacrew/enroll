@watir @screenshots
Feature: Create Primary Broker and Broker Agency
  In order to support individual and SHOP market clients, brokers must create and manage an account on the HBX for their organization.  Such organizations are referred to as a Broker Agency
  A Broker Representative
  Should be able to create a Broker Agency account

  Scenario: Broker Representative has not signed up on the HBX
    When I visit the HBX Broker Registration form
    And I click on New Broker Agency Tab
    Then I should see the New Broker Agency form
    When I enter personal information
    And I enter broker agency information
    And I enter office locations information
    And I click on Create Broker Agency
    Then I should see broker registration successful message

    When I login as an Hbx Admin
    And I click on brokers tab
    Then I should see the list of broker applicants
    When I click on the current broker applicant show button
    Then I should see the broker application
    When I click on approve broker button
    Then I should see the broker successfully approved message
    And I should receive an invitation email
    And I log out

    When I visit invitation url in email
    Then I should see the login page
    When I click on Create Account
    When I register with valid information
    Then I should see successful message with broker agency home page
    And I log out

    Given I haven't signed up as an HBX user
    When I visit the Employer portal
    And I sign up as a new employer
    Then I should see a successful sign up message
    And I create new employer profile
    
    When I click on the Broker Agency tab
    Then I should see no active broker
    When I click on Browse Borkers button
    Then I should see broker agencies index view
    When I search broker agency by name
    Then I should see broker agency
    When I click select broker button
    Then I should see confirm modal dialog box
    When I confirm broker selection
    Then I should see broker selected successful message
    When I click on the Broker Agency tab
    Then I should see broker active for the employer
    When I terminate broker
    Then I should see broker terminated message
    When I click on the Broker Agency tab
    Then I should see no active broker

