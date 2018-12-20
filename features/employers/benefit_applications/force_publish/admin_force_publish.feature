Feature: As an admin user I should have the ability to extend the OE
  of a given Employer with an extended enrollment.

  Background: Setup site, employer, and benefit application
    Given a CCA site exists with a benefit market
    And there is an employer ABC Widgets
    And this employer has a draft benefit application
    And this benefit application has a benefit package containing health benefits

  Scenario Outline: As an HBX Staff with Super Admin subroles I should <action> force publish button based on <date_to_compare_with> and publish_due_day_of_month of benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is <system_date_value> than the <date_to_compare_with>
    And the system date is <date_compare> than the publish_due_day_of_month
    And the user clicks Action for that Employer
    Then the user will <action> the Force Publish button

    Examples:
      | system_date_value  | date_to_compare_with                 | date_compare | action  |
      | greater            | earliest_start_prior_to_effective_on | less         | not see |
      | less               | monthly open enrollment end_on       | greater      | see     |

  Scenario Outline: As an HBX Staff with Super Admin subroles should see <display_message> based on open_enrollment_period start date of benefit application
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    When the system date is <system_date_value> open_enrollment_period start date
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button
    When the user clicks on Force Publish button
    Then the force published action should display <display_message>


    Examples:
      | system_date_value  | display_message                                      |
      | less than          | 'Employer(s) Plan Year date has not matched.'        |
      | greater than       | 'Employer(s) Plan Year was successfully published'   |
    