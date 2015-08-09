@watir @screenshots
Feature: Employee Sign Up when Employer exists and has a matching roster employer
  In order for the Employee to purchase insurance
  Given my Employer exists and Employee is on the Employee Roster
  Given my Employer has an unpublished Plan Year
  The Employee should not be able to match Employer
  When my Employer publishes the Plan Year
  The Employee should be able to match Employer
  The Employee should be able to purchase Insurance

  Scenario: New employee with existing person
    Given Employee has not signed up as an HBX user
    When Employee goes to the employee account creation page
    Then Soren White creates an HBX account
    Then Soren White should be logged on as an unlinked employee
    When I go to register as an employee
    Then I should see the employee search page
    When I enter the identifying info of Soren White
    Then I should not see the matched employee record form
    Then Soren White logs out
    When Soren White logs on to the Employer Portal
    Then Soren White creates a new employer profile
    When My employer publishes a plan year
    Then I should see a published success message
    Then My employer logs out
    When Soren White logs on to the Employee Portal
    Then Soren White should be logged on as an unlinked employee
    When I go to register as an employee
    Then I should see the employee search page
    When I enter the identifying info of Soren White
    Then I should see the matched employee record form
    When I accept the matched employer
    When I complete the matched employee form for Soren White
    Then I should see the dependents page
    When I click edit on baby Soren
    Then I should see the edit dependent form
    When I click delete on baby Soren
    Then I should see 2 dependents
    When I click Add Member
    Then I should see the new dependent form
    When I enter the dependent info of Sorens daughter
    When I click confirm member
    Then I should see 3 dependents
    When I click continue on the dependents page
    Then I should see the group selection page
    When I click continue on the group selection page
    Then I should see the list of plans
    When I select a plan on the plan shopping page
    When I click on purchase button on the coverage summary page
    Then I should see the receipt page
    Then I should see the "my account" page
    Then I should see the "Your Enrollment History" section
    When I click qle event
