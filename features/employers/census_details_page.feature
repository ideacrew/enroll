Feature: Employer can terminate EE from Census details page

Scenario: Employer terminated EE with DOT as today
  Given an employer exists
  And the employer has employees
  And the employer is logged in
  When they visit the Employee Roster
  And click on one of their employees
  Then they should see that employee's details
  And employer click on pencil symbol next to employee status bar
  Then employer should see the terminate button
  And employer clicks on terminate button
  Then employer should see the field to enter termination date
  And employer clicks on terminate button with DOT as today
  Then employer should see the success flash notice

Scenario: Employer terminated EE with DOT in past greater than 60 days
  Given an employer exists
  And the employer has employees
  And the employer is logged in
  When they visit the Employee Roster
  And click on one of their employees
  Then they should see that employee's details
  And employer click on pencil symbol next to employee status bar
  Then employer should see the terminate button
  And employer clicks on terminate button
  Then employer should see the field to enter termination date
  And employer clicks on terminate button with DOT in the past greater than 60 days
  Then employer should see the error flash notice
