Feature: Employee hired during renewal period
  In order for the New Employee to purchase insurance
  Given Employer is a Renewing Employer
  Given New Employee is on the Census Employee Roster
  Given New Employee does not have a pre-existing person
  Then New Employee should be able to match Employer
  And Employee should be able to purchase Insurance

  Scenario: New hire should be able to purchase Insurance under Active Plan Year during Renewing Plan Year Open Enrollment

    Given Renewing Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White is under open enrollment
      And Employer for Soren White has first_of_month rule
      And Employee has current hired on date

      # And Soren White already matched and logged into employee portal

      And Employee has not signed up as an HBX user
      And Soren White visits the employee portal
      When Soren White creates an HBX account
      When Employee goes to register as an employee
      Then Employee should see the employee search page
      When Employee enters the identifying info of Soren White
      Then Employee should see the matched employee record form
      When Employee accepts the matched employer
      When Employee completes the matched employee form for Soren White
      When Employee clicks continue on the dependents page
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects a plan on the plan shopping page
      Then Employee Soren White should see coverage effective date
      When Employee clicks on Confirm button on the coverage summary page
      Then Employee should see the receipt page
      Then Employee Soren White should see "my account" page with enrollment