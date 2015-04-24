@watir
Feature: Filter in Plan Selection Page

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
  When I enter the personal infomation of my existing person
  Then I should see the matched household information
  When I enter household information
  Then I should see the plan selection page
  When I enter filter in plan selection page
  Then I should see the filter results
  When I enter combind filter in plan selection page
  Then I should see the combind filter results
  When I select a plan in plan selection page
  Then I should see the plan thankyou page
