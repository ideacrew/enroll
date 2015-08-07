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

    Then admin@dc.gov/password logs on to hbx-portal
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
    When I click on Browse Brokers button
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

    When I click on Browse Brokers button
    Then I should see broker agencies index view
    When I search broker agency by name
    Then I should see broker agency
    When I click select broker button
    Then I should see confirm modal dialog box
    When I confirm broker selection
    Then I should see broker selected successful message
    And I log out

    Then ricky.martin@example.com/12345678 logs on to broker-agency-portal
    And I click on the Employers tab

    Then I should see Employer and click on legal name
    Then I should see the Employer Profile page as Broker
    When I publish a Plan Year as Broker
    When I click on Employees tab
    Then Broker clicks on the add employee button
    Then Broker creates a roster employee

    Then Broker sees employer census family created
    And I log out

    When I go to the employee account creation page
    When I enter my new account information
    Then I should be logged in
    When I go to register as an employee
    Then I should see the employee search page
    When I enter the identifying info of Broker Assisted
    Then Broker Customer should see the matched employee record form
    When I accept the matched employer
    Then I complete the matched employee form for Broker Assisted
    And I log out

    Then ricky.martin@example.com/12345678 logs on to broker-agency-portal
    And I click on the Employers tab

    Then I should see Employer and click on legal name
    Then I should see the Employer Profile page as Broker
    When I click on the Families tab
    Then Broker Assisted is a family
    Then Broker goes to the Consumer page
    Then Broker is on the consumer home page
    Then Broker shops for plans
    Then Broker sees covered family members
    Then Broker choses a healthcare plan
    And Broker confirms plan selection
    And Broker sees purchase confirmation
    Then Broker continues to the consumer home page
    And I log out


