Feature: As an admin user I should have the ability to extend the OE
  of a given Employer before open enrollment has closed.

  Background: Setup site, employer, and enrolling/renewing benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a enrollment_open benefit application
    And this benefit application has a benefit package containing health benefits

  Scenario: As an HBX Staff with Super Admin subroles I want to extend Open Enrollment for an Employer with an Enrolling/Renewing_Enrolling benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    And the user clicks Extend Open Enrollment
    And the user clicks Edit Open Enrollment
    Then the Choose New Open Enrollment Date panel is presented
    And the user enters a new open enrollment end date
    And the user clicks Extend Open Enrollment button
    Then a Successfully extended employer(s) open enrollment success message will display.
