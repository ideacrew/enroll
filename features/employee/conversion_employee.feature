Feature: Conversion employees can purchase coverage only through renewing plan year
  In order to make employees purchase coverage only using renewal plan year
  Employee should be blocked from buying coverage under off-exchange plan year

  Scenario: New Hire should not get effective date before renewing plan year start date
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employee has current hired on date
      And Employee has not signed up as an HBX user
      And Soren White visits the employee portal
      When Soren White creates an HBX account
      When Employee goes to register as an employee
      Then Employee should see the employee search page
      When Employee enters the identifying info of Soren White
      Then Employee should see the matched employee record form
      Then Employee Soren White should see renewing plan year start date as earliest effective date

  Scenario: New Hire can't buy coverage before open enrollment of renewing plan year through Shop for Plans
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee clicks "Shop for Plans" on my account page
      When Employee clicks continue on the group selection page
      Then Employee should see "employer-sponsored benefits not found" error message

  Scenario: New Hire can't buy coverage before open enrollment of renewing plan year through New Hire badge
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White published renewing plan year
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee clicks on New Hire Badge
      When Employee clicks continue on the group selection page
      Then Soren White should see "open enrollment not yet started" error message

  Scenario: New Hire can't buy coverage under off-exchange plan year using QLE
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee click the "Married" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see "employer-sponsored benefits not found" error message
          
  Scenario: New Hire can buy coverage during open enrollment of renewing plan year
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White is under open enrollment
      And Employee has current hired on date
      And Soren White already matched and logged into employee portal
      When Employee clicks on New Hire Badge
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with renewing plan year start date as effective date
      Then Soren White should see the receipt page with renewing plan year start date as effective date
      Then Employee should see "my account" page with enrollment

  Scenario: Existing Employee should not get effective date before renewing plan year start date
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employee has not signed up as an HBX user
      And Soren White visits the employee portal
      When Soren White creates an HBX account
      When Employee goes to register as an employee
      Then Employee should see the employee search page
      When Employee enters the identifying info of Soren White
      Then Employee should see the matched employee record form
      Then Employee Soren White should see renewing plan year start date as earliest effective date

  Scenario: Existing Employee can't buy coverage before open enrollment of renewing plan year
     Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White published renewing plan year
      And Soren White already matched and logged into employee portal
      When Employee clicks "Shop for Plans" on my account page
      When Employee clicks continue on the group selection page
      Then Soren White should see "open enrollment not yet started" error message

  Scenario: Existing Employee can't buy coverage under off-exchange plan year using QLE
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White published renewing plan year
      And Soren White already matched and logged into employee portal
      When Employee click the "Married" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Soren White should see "open enrollment not yet started" error message

  Scenario: Existing Employee can buy coverage during open enrollment of renewing plan year using QLE
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White is under open enrollment
      And Soren White already matched and logged into employee portal
      When Employee click the "Married" in qle carousel
      And Employee select a past qle date
      Then Employee should see confirmation and clicks continue
      Then Employee should see family members page and clicks continue
      Then Employee should see the group selection page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with renewing plan year start date as effective date
      Then Soren White should see the receipt page with renewing plan year start date as effective date
      Then Employee should see "my account" page with enrollment

  Scenario: Existing Employee can buy coverage during open enrollment of renewing plan year
    Given Conversion Employer for Soren White exists with active and renewing plan year
      And Employer for Soren White is under open enrollment
      And Soren White already matched and logged into employee portal
      When Employee clicks "Shop for Plans" on my account page
      When Employee clicks continue on the group selection page
      Then Employee should see the list of plans
      And I should not see any plan which premium is 0
      When Employee selects a plan on the plan shopping page
      Then Soren White should see coverage summary page with renewing plan year start date as effective date
      Then Soren White should see the receipt page with renewing plan year start date as effective date
      Then Employee should see "my account" page with enrollment
