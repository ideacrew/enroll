Feature: Employer should be able to view payment details

  Background: Setup site, employer
    Given a DC site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And an employer ABC Widgets exists with statements and premium payments
    And ABC Widgets employer has a staff role
    And staff role person logged in

  Scenario: An Employer should be able to view payment history
    When ABC Widgets is logged in and on the home page
    And staff role person clicked on billing tab
    Then the employer should see payment histroy
    When the employer clicks on statements
    Then the employer should see statements histroy
    When the employer clicks on pay my bill
    Then the employer should see billing information
