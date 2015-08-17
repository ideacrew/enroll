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
        #Then Soren White should be logged on as an unlinked employee
        When Employee goes to register as an employee
        Then Employee should see the employee search page
        When Employee enters the identifying info of Soren White
        Then Employee should not see the matched employee record form
        Then Soren White logs out

    When Soren White logs on to the Employer Portal
        Then Soren White creates a new employer profile
        When Employer publishes a plan year
        Then Employer should see a published success message
        Then Employer logs out

    When Soren White logs on to the Insured Portal
        #Then Soren White should be logged on as an unlinked employee
        When Employee goes to register as an employee
        Then Employee should see the employee search page
        When Employee enters the identifying info of Soren White
        Then Employee should see the matched employee record form
        When Employee accepts the matched employer
        When Employee completes the matched employee form for Soren White
        Then Employee should see the dependents page
        When Employee clicks edit on baby Soren
        Then Employee should see the edit dependent form
        When Employee clicks delete on baby Soren
        Then Employee should see 2 dependents
        When Employee clicks Add Member
        Then Employee should see the new dependent form
        When Employee enters the dependent info of Sorens daughter
        When Employee clicks confirm member
        Then Employee should see 3 dependents
        When Employee clicks continue on the dependents page
        Then Employee should see the group selection page
        When Employee clicks continue on the group selection page
        Then Employee should see the list of plans
        When Employee selects a plan on the plan shopping page
        When Employee clicks on purchase button on the coverage summary page
        Then Employee should see the receipt page
        Then Employee should see the "my account" page
        # Then Employee should see the "Your Enrollment History" section
        # When Employee clicks a qle event
        # Then Employee can purchase a plan
