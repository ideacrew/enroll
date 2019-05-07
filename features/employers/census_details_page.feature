Feature: Employee termination and Re-hire functionality

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for active initial employer with health benefits
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And employer ABC Widgets has active benefit application
    And there are 2 employees for ABC Widgets
    And Employees for ABC Widgets have both Benefit Group Assignments Employee role

  Scenario: Successful termination and rehire of an employee
    Given staff role person logged in
    And ABC Widgets employer visit the Employee Roster
    When employer clicks on Actions drop down for one of active employee
    Then employer should see the terminate button
    When employer clicks on terminate button
    Then employer should see Enter termination date to remove text
    And employer clicks on Terminate Employee button with date as pastdate
    Then employer should see the terminated success flash notice
    When employer clicks on button terminated for datatable
    And employer clicks on Actions drop down for one of terminated employee
    When employer clicks on rehire button
    And employer clicks on submit button by entering todays date
    Then employer should see the rehired success flash notice

#  Scenario: Employer terminated EE with DOT in past greater than 60 days
#    Given staff role person logged in
#    And ABC Widgets employer visit the Employee Roster
#    And employer clicks on Actions drop down for one of active employee
#    And employer should see the terminate button
#    When employer clicks on terminate button
#    Then employer should see Enter termination date to remove text
#    And employer clicks on Terminate Employee button with date as past greater than 60 days
#    Then employer should see the error flash notice
