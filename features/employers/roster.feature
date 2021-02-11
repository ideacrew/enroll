Feature: Employer can view their employees

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And ABC Widgets employer has a staff role
    And there are 2 employees for ABC Widgets
    When staff role person logged in
    Then ABC Widgets employer visit the Employee Roster

  Scenario: Employer views their employees and terminates one employee
    Given employer selects one of their employees on Employee Roster
    When employer should see census employee's details
    And employer clicks on back button
    Then employer should see employee roaster
    When employer clicks on Actions drop down for one of active employee
    And employer should see the terminate button
    And employer clicks on terminate button
    Then employer should see Enter termination date to remove text
    When employer clicks on Terminate Employee button with date as pastdate
    Then employer should see the terminated success flash notice
    When employer clicks on button terminated for datatable
    And employer clicks on terminated employee
    Then employer should see terminated census employee's details
    When employer clicks on back button
    And employer should see employee roaster
    Then employer clicks logout

  Scenario: Employer views their employees and this ER has linked EEs
    Given employer clicks on linked employee with address
    Then employer should not see the address on the roster
    And employer clicks on cancel button
    When employer clicks on linked employee without address
    Then employer should see the address on the roster
    And employer populates the address field
    When employer clicks on update employee
    Then employer should not see the address on the roster
    And employer clicks on cancel button
    When employer clicks on non-linked employee with address
    Then employer clicks on cancel button
    When employer clicks on non-linked employee without address
    Then employer should see the address on the roster
    And employer populates the address field
    And employer clicks on update employee
    And employer should see the address on the roster
    Then employer logs out

  Scenario: Employer adds employee with future hire date
    Given employer selects Add New Employee button on employee roster
    Then fill the form with hired date as future date
    Then employer should see the message Your employee was successfully added to your roster on page
    And employer logs out

  Scenario: Employee with active enrollment for display on roster
    Given benefit market catalog exists for active initial employer with health benefits
    And employer ABC Widgets has active benefit application
    And employees for ABC Widgets have a selected coverage
    And employee has updated enrollment details
    When employer clicks an employee from the roster
    Then employer should see the active enrollment tile
    And employer logs out

