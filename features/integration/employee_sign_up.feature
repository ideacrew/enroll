@watir
Feature: Employee Sign Up
  In order to get access to the site
  As an employee
  I need to create an account and match an existing record

  Scenario: New employee with existing person
    Given I do not exist as a user
    And I have an existing employee record
    And I have an existing person record
    When I go to the employee account creation page
    When I enter my new account information
    Then I should be logged in
    When I go to register as an employee
    Then I should see the employee search page
    When I enter the identifying info of my existing person
    Then I should see the matched employee record form
    When I complete the matched employee form
    Then I should see the dependents page
    When I click continue on the dependents page
    Then I should see the group selection page
    When I click continue on the group selection page
    Then I should see the plan shopping page
