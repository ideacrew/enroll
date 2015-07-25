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

    Given the current broker receives the activation link
    Then the broker click on the activation link
    Then I should the login page
    When I click on Create Account
    Then I should see User registration form
    When I enter login and password 
    And create account
    Then I should see login successful message
    And I should broker agency home page

