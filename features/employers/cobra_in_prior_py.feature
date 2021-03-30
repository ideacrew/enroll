Feature: Census Employee COBRA functionality

  Background: Setup Setup site, employer, and benefit applications in prior, active and renewal years
    Given a DC site exists with a benefit market
    Given benefit market catalog exists for existing employer
    And the Prior PY feature configuration is enabled
    And there is an employer EnterPrise Limited
    And EnterPrise Limited employer has a staff role
    And there exists Patrick Doe employee for employer EnterPrise Limited

  Scenario: Employer initiating cobra for census employee with cobra begin date
            falling in terminated plan year

    Given staff role person logged in
    And employer EnterPrise Limited has terminated and active benefit applications
    And employee Patrick Doe has past hired on date
    And employee Patrick Doe already matched with employer EnterPrise Limited and not logged into employee portal
    And employee Patrick Doe has employer sponsored enrollment in terminated py
    And EnterPrise Limited employer visit the Employee Roster
    And EnterPrise Limited employer terminates employees with termination date in terminated plan year
    Then employer clicks on terminated filter
    And employer clicks on Actions drop down for one of active employee
    And employer should see the Initiate cobra button
    When employer clicks on Initiate cobra button
    Then employer should see Enter effective date for Initiate cobra Action
    And employer should see default cobra start date
    When EnterPrise Limited employer clicks on Initiate COBRA button
    Then employer should see the Initiate cobra success flash notice
    And employer clicks on all employees
    And employer should see census employee status as Cobra linked
    And employee should have cobra sponsored enrollments generated