Feature: Only HBX Staff will be able to see & access the Reset Password Feature.

  Background: Setup site, employer, benefit application and active employee
    Given a CCA site exists with a benefit market
    Given benefit market catalog exists for enrollment_open initial employer with health benefits
    And Qualifying life events are present

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Reset Password button
    Given that a user with a HBX staff role with <subrole> subrole exists and is logged in
    And the user is on the User Accounts tab of the Admin Dashboard
    Then user will click on action tab
    Then Hbx Admin should see Reset Password link in action drop down
    When Hbx Admin click on Reset Password link in action drop down

    Examples:
      | subrole       | action  |
      | HBX Staff     | see     |
