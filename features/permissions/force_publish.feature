Feature: As a Super Admin & tier3 I will be the only user
  that is able to see & access the "Force Publish" Feature.

  Scenario Outline: HBX Staff with <subrole> subroles should <action> Force Publish button
    Given a Hbx admin with <subrole> role exists
    And a Hbx admin logs on to Portal
    And the employer has draft plan year
    And Hbx Admin navigate to main page
    And system date is between submission deadline & application effective date
    And Hbx Admin clicks on Employers link
    When the Hbx Admin clicks on the Action button
    Then Hbx Admin should <action> an Force Publish button

    Examples:
      | subrole               | action  |
      | super_admin           | see     |
      | hbx_tier3             | see     |
      | hbx_staff             | not see |
      | hbx_read_only         | not see |
      | hbx_csr_supervisor    | not see |
