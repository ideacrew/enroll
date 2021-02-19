@wip
Feature: Any Person with User account should be able to add employee role

  Background: Setup site and benefit market catalog
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And there is an employer Windsor Widgets
    And initial employer Windsor Widgets has enrollment_open benefit application
    And there is a census employee record for Patrick Doe for employer Windsor Widgets

  Scenario: Employer POC should be able to enroll as an employee via Add Account in My Hub page
    And there is an employer Xfinity Widgets
    And Xfinity Widgets employer has Patrick Doe as employer staff
    And staff role person logged in
    And person with staff role signs in and visits My Hub page
    And person clicks on Add Account tab
    And person clicks on EMPLOYEE link on pop up
    Then person should see the employee privacy text
    And person should see their indentifying information
    Then person enters ssn under personal information for Patrick Doe
    And Employee accepts the matched employer
    And Employee completes the matched employee form for Patrick Doe
    And person logs out