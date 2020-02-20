Feature: As a Super Admin I will be the only user
  that is able to see & access the "Force Publish" Feature.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for draft initial employer with health benefits
    And there is an employer ABC Widgets
    And employer ABC Widgets has draft benefit application

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Force Publish button
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And system date is between submission deadline & OE End date
    And the user is on the Employer Index of the Admin Dashboard
    When the user clicks Action for that Employer
    Then the user will <action> the Force Publish button

    Examples:
      | subrole       | action  |
      | Super Admin   | see     |
      | HBX Tier3     | see     |
      | HBX Staff     | not see |
      | HBX Read Only | not see |
      | Developer     | not see |
