Feature: As an admin user I should have the ability to extend the OE
  of a given Employer with an extended enrollment.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a draft benefit application
    And this benefit application has a benefit package containing health benefits

  Scenario: As an HBX Staff with Super Admin subroles I should not be able to extend Open Enrollment for an Employer with a enrollment_extended benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is greater than the earliest_start_prior_to_effective_on
    And the system date is less than the publish_due_day_of_month
    And the user clicks Action for that Employer
    Then the user will not see the Force Publish button

  Scenario: As an HBX Staff with Super Admin subroles I should not be able to extend Open Enrollment for an Employer with a enrollment_extended benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is less than the monthly open enrollment end_on
    And the system date is greater than the publish_due_day_of_month
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button

  Scenario: As an HBX Staff with Super Admin subroles I should not be able to extend Open Enrollment for an Employer with a enrollment_extended benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is less than open_enrollment_period start date
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button
    When the user clicks on Force Publish button
    Then the force published action should display 'Employer(s) Plan Year date has not matched.' message

  Scenario: As an HBX Staff with Super Admin subroles I should not be able to extend Open Enrollment for an Employer with a enrollment_extended benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is greater than open_enrollment_period start date
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button
    When the user clicks on Force Publish button
    Then the force published action should display 'Employer(s) Plan Year was successfully published' message