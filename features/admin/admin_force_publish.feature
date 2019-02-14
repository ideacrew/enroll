Feature: As an admin user I should have the ability to extend the OE
  of a given Employer with an extended enrollment.


  Scenario Outline: As an HBX Staff with Super Admin subroles I should <action> force publish button based on <date_to_compare_with> and publish_due_day_of_month of benefit application
    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has draft plan year
    And Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    When the system date is <system_date_value> than the <date_to_compare_with>
    And the system date is <date_compare> than the publish_due_day_of_month
    When the Hbx Admin clicks on the Action button
    Then Hbx Admin should <action> an Force Publish button

    Examples:
      | system_date_value  | date_to_compare_with                 | date_compare | action  |
      | less               | application_effective_date           | less         | not see |
      | less               | application_effective_date           | greater      | see     |
      | greater            | application_effective_date           | greater      | not see |

  Scenario: Draft application published between submission deadline & application effective date
    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has draft plan year
    And Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And system date is between submission deadline & application effective date
    When employer FTE count is less than or equal to shop:small_market_employee_count_maximum
    And employer primary address state is DC
    And the Hbx Admin clicks on the Action button
    And Hbx Admin should see an Force Publish button
    And the user clicks on Force Publish button
    And the user clicks submit button
    Then the force publish successful message should be displayed

  Scenario Outline: Draft application published between submission deadline & application effective date

    Given a Hbx admin with super_admin role exists
    And a Hbx admin logs on to Portal
    And the employer has draft plan year
    And Hbx Admin navigate to main page
    And Hbx Admin clicks on Employers link
    And system date is between submission deadline & application effective date
    When employer FTE count is <compare_fte> to shop:small_market_employee_count_maximum
    And employer primary address state <state_check> DC
    And the Hbx Admin clicks on the Action button
    And Hbx Admin should see an Force Publish button
    And the user clicks on Force Publish button
    And the user clicks submit button
    Then a warning message will appear

    Examples:
      |compare_fte         |     state_check    |
      |more than           |        is          |
      |more than           |        is not      |
      |less than or equal  |        is not      |


