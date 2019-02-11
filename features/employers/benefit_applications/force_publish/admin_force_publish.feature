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
    And system date is between submission deadline & OE End date
    When the system date is <system_date_value> than the <date_to_compare_with>
    And the system date is <date_compare> than the publish_due_day_of_month
    And the user clicks Action for that Employer
    Then the user will <action> the Force Publish button

    Examples:
      | system_date_value  | date_to_compare_with                 | date_compare | action  |
      | greater            | earliest_start_prior_to_effective_on | less         | not see |
      | less               | monthly open enrollment end_on       | greater      | see     |

  Scenario: Draft application published between submission deadline & OE End date
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And system date is between submission deadline & OE End date
    When ABC widgets FTE count is less than or equal to shop:small_market_employee_count_maximum
    And ABC widgets primary address state is MA
    And the user clicks Action for that Employer
    Then the user will see the Force Publish button
    When the system date is greater than open_enrollment_period start date
    And the user clicks on Force Publish button
    Then the force published action should display 'Employer(s) Plan Year was successfully published'

  Scenario Outline: Draft application published between submission deadline & OE End date
    Given that a user with a HBX staff role with Super Admin subrole exists and is logged in
    And the user is on the Employer Index of the Admin Dashboard
    And system date is between submission deadline & OE End date
    And ABC widgets FTE count is <compare_fte> to shop:small_market_employee_count_maximum
    And ABC widgets primary address state <state_check> MA
    And the user clicks Action for that Employer
    And the user clicks on Force Publish button
    Then a warning message will appear
    And ask to confirm intention to publish.

    Examples:
      |compare_fte         |     state_check    |
      |more than           |        is          |
      |more than           |        is not      |
      |less than or equal  |        is not      |
