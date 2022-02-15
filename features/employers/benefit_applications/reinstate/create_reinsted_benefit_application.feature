Feature: Ability for Admin to create an Reinstated benefit application and allow employees to plan shop

  Background: Setup site, employer, and benefit market catalogs
    Given the shop market configuration is enabled
    Given a CCA site exists with a benefit market
    And benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And the Reinstate feature configuration is enabled
    And Qualifying life events are present
    Given initial employer ABC Widgets has active benefit application
    And there is a census employee record and employee role for Patrick Doe for employer ABC Widgets
    And census employee Patrick Doe has a past date of hire
    And employees for employer ABC Widgets have selected a coverage

Scenario: Initial Employer is in termination pending. Admin is able to create reinstated benefit application
          and employees are able to plan shop in both active and future reinstated applications

    Given that a user with a HBX staff role with HBX staff subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to terminate
    When the user clicks Actions for current benefit application
    When the user clicks Actions for that benefit application
    Then the user will see Terminate button
    When the user enters any_day and other details for voluntary termination
    When user clicks submit button
    Then user should see termination successful message
    And update rating area
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks the Plan Years button
    Then the user will select benefit application to reinstate
    And Admin reinstates benefit application
    Then Admin will see a Successful message
    And I click on log out link
    And staff role person logged in
    When ABC Widgets is logged in and on the home page
    And employee staff role person clicked on benefits tab
    Then employer should see termination pending and reinstated benefit_application
    And employee staff role person clicks on employees link
    And employee staff role person clicks employee Patrick Doe
    Then the user should see a dropdown for Reinstated Plan Year benefit package
    And census employee Patrick Doe has benefit group assignment of the future reinstated benefit application
    And I click on log out link
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Losing other health insurance" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on group selection page
    Then Employee should see the list of plans
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    Then Employee clicks back to my account button
    And employee Patrick Doe of employer ABC Widgets most recent HBX Enrollment should be under the future reinstated benefit application

  Scenario Outline: Admin is able to create reinstated benefit application and employees are able to plan shop in the new reinstaed PY
    
    And initial employer ABC Widgets application <to_state>
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will see the Plan Years button
    Then the user will select benefit application to reinstate
    And Admin reinstates benefit application
    Then Admin will see a Successful message
    And user logs out
    And staff role person logged in
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on benefits tab
    Then employer should see py_states states
    And staff role person clicks on employees link
    And staff role person clicks on employee Patrick Doe
    Then the user should see a dropdown for Reinstated Plan Year benefit package
    And user logs out
    And employee Patrick Doe already matched with employer ABC Widgets and logged into employee portal
    When Employee click the "Married" in qle carousel
    And Employee select a current qle date
    Then Employee should see confirmation and clicks continue
    Then Employee should see family members page and clicks continue
    Then Employee should see the group selection page
    When Employee clicks continue on group selection page
    Then Employee should see the list of plans
    When Employee selects a plan on the plan shopping page
    When Employee clicks on Confirm button on the coverage summary page
    And Employee clicks back to my account button
    Then employee Patrick Doe of employer ABC Widgets most recent HBX Enrollment should be under the reinstated benefit application

    Examples:
      |    to_state          |  py_states |
      | retroactive_canceled |  [Canceled, Reinstated] | 
      # |  canceled            |  [Canceled, Reinstated] | flaky
      |  terminated          |  [Coverage Terminated, Reinstated] |
