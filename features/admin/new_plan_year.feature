Feature: As a Super Admin I will be the only user
  that is able to see & access the "Create Plan Year" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a enrollment_open benefit application
    And this benefit application has a benefit package containing health benefits
    And that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And the user clicks Action for that Employer

  Scenario: HBX Staff with Super Admin subroles should see Create Plan Year button
    Given that the user has clicked the Create Plan Year button for this Employer
    When the user selects an input in the Effective Start date drop down
    Then the Effective End Date will populate with a date equal to one year minus 1 day from the Effective Start Date
    And the Effective End Date will not be editable.